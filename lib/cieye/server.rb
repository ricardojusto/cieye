# frozen_string_literal: true

require "socket"
require "json"

module Cieye
  # Cieye::Server
  class Server
    attr_reader :socket_path
    attr_accessor :server, :running, :thread, :callback

    def initialize(socket_path, &block)
      @socket_path = socket_path
      @callback = block
      @server = nil
      @running = false
    end

    def start
      start_server
      watch_server
    end

    def stop
      self.running = false
      server&.close
      File.delete(socket_path) if File.exist?(socket_path)
      thread&.join
    end

    private

    def start_server
      File.delete(socket_path) if File.exist?(socket_path)
      self.server = UNIXServer.new(socket_path)
      self.running = true
    end

    def watch_server
      self.thread = Thread.new do
        while running
          begin
            handle_client(server.accept)
          rescue Errno::EBADF, IOError, IO::WaitReadable, Errno::EINVAL
            break
          rescue StandardError => e
            Cieye::Logger.warn("Server: #{e.message}")
            break
          end
        end
      end
    end

    def handle_client(client)
      while (line = client.gets)
        begin
          data = JSON.parse(line)
          callback.call(data)
        rescue JSON::ParserError
          next
        end
      end
      client&.close
    end
  end
end
