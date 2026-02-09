# frozen_string_literal: true

require "fileutils"

module Cieye
  # Handles cleanup of reports and JSON files
  class Cleaner
    def self.cleanup(artifact_path = nil)
      artifact_path ||= Cieye.artifact_path

      # Remove wildcard JSON results
      FileUtils.rm_f(Dir.glob(File.join(artifact_path, "rspec_results*.json")))

      # Remove HTML reports
      FileUtils.rm_f(File.join(artifact_path, "rspec_failed_report.html"))
      FileUtils.rm_f(File.join(artifact_path, "rspec_execution_report.html"))

      # Remove coverage report if exists
      coverage_path = File.join(Dir.pwd, "coverage/index.html")
      FileUtils.rm_f(coverage_path) if File.exist?(coverage_path)

      Cieye::Logger.info("Old RSpec reports, JSON results and Simplecov report cleared.")
    end

    def self.cleanup_before_run(artifact_path = nil)
      cleanup(artifact_path)
    end

    def self.cleanup_after_run(artifact_path = nil)
      # Optional: cleanup JSON files after generating HTML reports
      artifact_path ||= Cieye.artifact_path
      FileUtils.rm_f(Dir.glob(File.join(artifact_path, "rspec_results*.json")))
    end
  end
end
