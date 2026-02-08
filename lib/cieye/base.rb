# frozen_string_literal: true

require "fileutils"

module Cieye
  class Error < StandardError; end

  def self.artifact_path
    @artifact_path ||= File.join(Dir.pwd, "tmp/cieye")
  end

  def self.artifact_path=(path)
    @artifact_path = path
  end

  def self.ensure_artifact_dir!
    FileUtils.mkdir_p(artifact_path)
  end

  def self.config_path
    project_config = File.join(Dir.pwd, ".cieye_rspec")
    return project_config if File.exist?(project_config)

    File.join(__dir__, "config", ".cieye_rspec")
  end
end
