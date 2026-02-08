# frozen_string_literal: true

require "fileutils"

# The Cieye module provides tools for monitoring Continuous Integration
# pipelines and aggregating build status data across multiple providers
module Cieye
  MAX_SOCKET_PATH_LEN = 104

  class << self
    # def configure
    #   yield self
    # end

    def artifact_path
      @artifact_path ||= File.join(Dir.pwd, "tmp", "cieye")
    end

    # def artifact_path=(path)
    #   target = path || File.join(Dir.pwd, "tmp", "cieye")
    #   full_path = File.expand_path(target)
    #   socket_path = File.join(full_path, "cieye.sock")

    #   if socket_path.bytesize > MAX_SOCKET_PATH_LEN
    #     raise Cieye::Error, "Path too long for unix socket: #{socket_path.bytesize} / #{MAX_SOCKET_PATH_LEN} chars"
    #   end

    #   @artifact_path = full_path
    # end

    def ensure_artifact_dir!
      FileUtils.mkdir_p(artifact_path) unless Dir.exist?(artifact_path)
    end
  end
end
