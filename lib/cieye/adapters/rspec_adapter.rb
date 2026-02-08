# frozen_string_literal: true

require "rspec/core/formatters/base_text_formatter"
require "socket"
require "json"

module Cieye
  module Adapters
    # RSpec formatter that hijacks stdout/stderr and sends test results to Cieye monitor via Unix socket
    class RSpecAdapter < RSpec::Core::Formatters::BaseTextFormatter
      # Register for RSpec lifecycle events and the 'close' event for stream cleanup
      RSpec::Core::Formatters.register self, :start, :example_passed, :example_failed, :example_pending, :close

      def initialize(output)
        super
        @worker_id = ENV["TEST_ENV_NUMBER"].to_s.empty? ? "1" : ENV["TEST_ENV_NUMBER"]
        @socket_path = File.join(Cieye.artifact_path, "cieye.sock")
        @total_examples = 0
        @examples_completed = 0

        # 1. Store original streams to restore them in the 'close' method
        @old_stdout = $stdout.dup
        @old_stderr = $stderr.dup

        # 2. Create two separate IO pipes to keep Stdout and Stderr distinct
        @out_r, @out_w = IO.pipe
        @err_r, @err_w = IO.pipe

        # 3. Hijack the global constants
        $stdout.reopen(@out_w)
        $stderr.reopen(@err_w)

        @threads = []
        # 4. Spawn background threads to monitor each pipe independently
        @threads << spawn_log_thread(@out_r, "stdout")
        @threads << spawn_log_thread(@err_r, "stderr")
      end

      # RSpec start hook: knows how many tests this worker will run
      def start(notification)
        @total_examples = notification.count
      end

      def example_passed(notification)  = send_update("passed", notification.example)
      def example_failed(notification)  = send_update("failed", notification.example)
      def example_pending(notification) = send_update("pending", notification.example)

      # Cleanup method: Restores terminal streams and shuts down background threads
      def close(_notification)
        # Restore original $stdout and $stderr so final reports print normally
        $stdout.reopen(@old_stdout)
        $stderr.reopen(@old_stderr)

        # Closing the writers triggers 'each_line' in the threads to finish
        begin
          @out_w.close
        rescue StandardError
          nil
        end
        begin
          @err_w.close
        rescue StandardError
          nil
        end

        # Wait briefly for threads to flush remaining data
        @threads.each do |t|
          t.join(0.1)
        rescue StandardError
          nil
        end

        begin
          @out_r.close
        rescue StandardError
          nil
        end
        begin
          @err_r.close
        rescue StandardError
          nil
        end
      end

      private

      # Reads from a specific pipe and sends categorized JSON to the monitor
      def spawn_log_thread(reader, stream_name)
        Thread.new do
          reader.each_line do |line|
            clean_line = line.chomp
            next if clean_line.empty?

            # Identify if the line is an ERROR, WARNING, or LOG based on keywords
            level = categorize(clean_line, stream_name)

            send_payload(
              { type: "log",
                level: level,
                stream: stream_name,
                message: clean_line }
            )
          end
        rescue IOError
          # Pipe closed, exit thread gracefully
        end
      end

      # Simple heuristic to tag messages for the Monitor background colors
      def categorize(message, stream)
        # High priority: Check for explicit error keywords
        return "error"   if /error|exception|failed|fatal|invalid/i.match?(message)

        # Medium priority: Check for warnings or deprecations
        return "warning" if /warning|deprecated|timeout|caution/i.match?(message)

        # Anything on STDERR is at least a warning even if no keyword is found
        return "warning" if stream == "stderr"

        # Default fallback for standard STDOUT prints
        "log"
      end

      # Standard test progress update
      def send_update(status, example)
        @examples_completed += 1
        percent = @total_examples > 0 ? (@examples_completed.to_f / @total_examples) : 0

        send_payload(
          { worker: @worker_id,
            type: "result",
            status: status,
            percent: percent,
            file: example.file_path.split("/").last }
        )
      end

      # Sends a Hash as JSON over the Unix Socket
      def send_payload(payload_hash)
        # @old_stdout.puts "DEBUG: Sending payload: #{payload_hash[:type]} - #{payload_hash[:status] || payload_hash[:message]}"
        socket = UNIXSocket.new(@socket_path)
        socket.puts(payload_hash.to_json)
        socket.close
      rescue Errno::ENOENT, Errno::ECONNREFUSED => e
        warn "DEBUG: Socket error: #{e.message}"
        # Monitor is likely not running; fail silently
      end
    end
  end
end
