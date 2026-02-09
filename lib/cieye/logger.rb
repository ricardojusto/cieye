# frozen_string_literal: true

module Cieye
  # Lightweight logger for operational messages.
  #
  # @example
  #   Cieye::Logger.info("Server started on socket /tmp/cieye.sock")
  #   Cieye::Logger.error("Connection refused")
  #   Cieye::Logger.warn("Retrying in 5 seconds...")
  #   Cieye::Logger.deprecated("Use Cieye.monitor instead of Cieye.start_monitor")
  module Logger
    class << self
      def info(message)
        log("INFO", message)
      end

      def error(message)
        log("ERROR", message)
      end

      def warn(message)
        log("WARNING", message)
      end

      def deprecated(message)
        log("DEPRECATED", message)
      end

      private

      def log(level, message)
        Kernel.warn "[Cieye] #{level}: #{message}"
      end
    end
  end
end
