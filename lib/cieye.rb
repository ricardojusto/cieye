# frozen_string_literal: true

require_relative "cieye/version"
require_relative "cieye/base"
require_relative "cieye/logger"
require_relative "cieye/config"
require_relative "cieye/server"
require_relative "cieye/store"
require_relative "cieye/tui"
require_relative "cieye/monitor"
require_relative "cieye/reporter"
require_relative "cieye/cleaner"
require_relative "cieye/socket_client"
# RSpec adapter is loaded by RSpec when configured in .cieye_rspec
# require_relative "cieye/adapters/rspec_adapter"

# Cieye
module Cieye
  class << self
    def monitor(worker_count = 4, generate_html: true, &block)
      raise ArgumentError, "Block required" unless block_given?

      ensure_artifact_dir!

      monitor_pid = Monitor.start(worker_count)

      # Allow server to initialize
      sleep 0.5

      begin
        exit_status = block.call

        # Catch up final updates to be processed
        sleep 0.5

        # Generate HTML reports if requested
        if generate_html
          Reporter.generate(artifact_path)
          Reporter.report_summary(artifact_path)
        end

        exit_status
      ensure
        Monitor.stop(monitor_pid)
      end
    end

    # For manual control (advanced usage)
    #
    # @example
    #   monitor_pid = Cieye.start_monitor(4)
    #   # ... run your tests ...
    #   Cieye.stop_monitor(monitor_pid)
    def start_monitor(worker_count = 4)
      ensure_artifact_dir!
      Monitor.start(worker_count)
    end

    def stop_monitor(pid)
      Monitor.stop(pid)
    end
  end
end
