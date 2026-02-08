# frozen_string_literal: true

require "socket"
require "json"
require "lipgloss"

# Ensure lib directory is in the load path
$LOAD_PATH.unshift File.expand_path("..", __dir__) unless $LOAD_PATH.include?(File.expand_path("..", __dir__))

require "cieye/base"
require "cieye/store"
require "cieye/server"
require "cieye/tui"
require "cieye/reporter"
require "cieye/cleaner"

module Cieye
  # Cieye::Monitor
  class Monitor
    def self.start(worker_count)
      pid = spawn("ruby #{__FILE__} #{worker_count}")
      at_exit do
        begin
          Process.kill("TERM", pid)
        rescue StandardError
          nil
        end
        print "\e[?25h" # Show cursor
      end
      pid
    end

    def self.stop(pid)
      return unless pid

      begin
        Process.kill(0, pid)

        # If we get here, process is still running
        10.times do
          sleep 0.1
          begin
            Process.kill(0, pid)
          rescue Errno::ESRCH
            print "\e[?25h"
            return
          end
        end

        # Process is taking too long, force terminate
        begin
          Process.kill("TERM", pid)
        rescue StandardError
          nil
        end

        begin
          Process.wait(pid)
        rescue StandardError
          nil
        end
      rescue Errno::ESRCH
        # Process already exited - nothing to do
      end

      # Ensure cursor is visible
      print "\e[?25h"
      $stdout.flush
    end

    attr_reader :socket_path, :server, :store, :tui

    def initialize(worker_count)
      @socket_path = File.join(Cieye.artifact_path, "cieye.sock")
      @worker_count = worker_count.to_i
      @running = true

      # Data Layer
      @store = Cieye::Store.new(@worker_count)

      # Network Layer
      @server = Cieye::Server.new(socket_path) { |data| @store.update(data) }

      # UI Layer
      @tui = Cieye::Tui.new(@worker_count)
    end

    def run
      tui.screen_setup

      trap("TERM") { @running = false }
      trap("INT") { @running = false }

      server.start

      begin
        while @running
          tui.render(store)
          if store.all_finished?
            @running = false
            break
          end
          sleep 0.1 # 10 fps
        end

        # Small delay to ensure all socket messages are processed
        sleep 0.3

        tui.finalize(store)
      rescue StandardError => e
        @running = false
        tui.screen_restore
        raise Cieye::Error, e.message
      ensure
        server.stop
      end
    end
  end
end

Cieye::Monitor.new(ARGV[0] || 4).run if __FILE__ == $0
