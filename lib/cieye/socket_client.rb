# frozen_string_literal: true

require "socket"
require "json"

module Cieye
  # Sends test results from the test runner to the Cieye server via Unix socket
  class SocketClient
    def initialize(socket_path = nil)
      @socket_path = socket_path || File.join(Cieye.artifact_path, "cieye.sock")
    end

    def report(test_name, status, duration: 0)
      payload = {
        test_name: test_name,
        status: status,
        duration: duration,
        timestamp: Time.now.to_i
      }.to_json

      send_to_socket(payload)
    rescue StandardError => e
      Cieye::Logger.warn("SocketClient: #{e.message}")
    end

    private

    def send_to_socket(payload)
      return unless File.exist?(@socket_path)

      UNIXSocket.open(@socket_path) do |socket|
        socket.puts(payload)
      end
    end
  end
end
