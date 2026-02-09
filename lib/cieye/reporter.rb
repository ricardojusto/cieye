# frozen_string_literal: true

require "json"
require "fileutils"
require "erb"

module Cieye
  # Generates HTML reports from RSpec JSON results
  class Reporter
    attr_reader :failed_examples, :all_examples, :artifact_path

    def initialize(artifact_path = nil)
      @artifact_path = artifact_path || Cieye.artifact_path
      @failed_examples = []
      @all_examples = []
    end

    def self.generate(artifact_path = nil)
      new(artifact_path).generate
    end

    def self.report_summary(artifact_path = nil)
      new(artifact_path).report_summary
    end

    def generate
      json_files = Dir.glob(File.join(artifact_path, "rspec_results*.json"))
      return Cieye::Logger.warn("No RSpec JSON results found.") if json_files.empty?

      collate_data(json_files)
      generate_execution_report
      generate_failed_report if failed_examples.any?
    end

    def report_summary
      failed_report_path = File.join(artifact_path, "rspec_failed_report.html")
      execution_report_path = File.join(artifact_path, "rspec_execution_report.html")
      coverage_report_path = File.join(Dir.pwd, "coverage/index.html")

      active_reports = [
        { path: execution_report_path, icon: "📊", label: "Full Report" },
        { path: failed_report_path,    icon: "⭕", label: "Failed Specs" },
        { path: coverage_report_path,  icon: "👀", label: "Code Coverage" }
      ].select do |r|
        File.exist?(r[:path]) &&
          (r[:path] != coverage_report_path || ENV["COVERAGE"].to_s.casecmp("true").zero?)
      end

      return if active_reports.empty?

      puts "\nReports:"
      puts "-" * 60

      active_reports.each_with_index do |report, index|
        abs_path = File.expand_path(report[:path])
        display_label = " #{report[:icon]}  #{report[:label].rjust(15)}"
        display_text  = "#{display_label}: #{report[:path]}"

        # OSC 8 Sequence for clickable links
        url = "file://#{abs_path}"
        link = "\e]8;;#{url}\a#{display_text}\e]8;;\a"

        padding = link.length - display_text.length
        puts link.center(60 + padding)
        puts "-" * 60 unless index == active_reports.size - 1
      end

      puts "-" * 60
      puts "\n"
    end

    private

    def collate_data(files)
      files.each do |file|
        next unless File.exist?(file)
        next if File.zero?(file)

        begin
          data = JSON.parse(File.read(file))
          examples = data.fetch("examples", [])
          @all_examples.concat(examples)
          @failed_examples.concat(examples.select { |e| e["status"] == "failed" })
        rescue JSON::ParserError
          next
        end
      end
    end

    def generate_execution_report
      groups = all_examples.group_by { |e| File.dirname(e["file_path"]) }.sort.to_h
      slowest_specs = all_examples.sort_by { |e| e["run_time"] || 0 }.last(20).reverse

      # Prepare template variables
      @finished_at = Time.now.getlocal.strftime("%Y-%m-%d %H:%M:%S %Z")
      @slowest_specs_rows = slowest_specs.map { |e| render_slow_spec_row(e) }.join
      @folder_summary_rows = groups.map { |folder, specs| render_summary_row(folder, specs) }.join
      @detailed_tables = groups.map { |folder, specs| render_detailed_table(folder, specs) }.join

      # Render ERB template
      template_path = File.join(__dir__, "templates", "execution_report.html.erb")
      template = ERB.new(File.read(template_path))
      html = template.result(binding)

      output_path = File.join(artifact_path, "rspec_execution_report.html")
      File.write(output_path, html)
    end

    def render_slow_spec_row(e)
      file_name = File.basename(e["file_path"])
      <<-HTML
      <tr>
        <td class="fw-bold">#{e["run_time"].round(2)}s</td>
        <td>#{file_name}</td>
        <td>#{e["full_description"]}</td>
        <td><span class="text-muted">:#{e["line_number"]}</span></td>
      </tr>
      HTML
    end

    def render_summary_row(folder, specs)
      total_time = specs.sum { |e| e["run_time"] || 0 }
      anchor = folder.gsub(/[^a-zA-Z0-9]/, "_")
      <<-HTML
      <tr>
        <td><a href="##{anchor}">#{folder}</a></td>
        <td>#{specs.size}</td>
        <td>#{total_time.round(2)}s</td>
        <td>#{(total_time / specs.size).round(3)}s</td>
      </tr>
      HTML
    end

    def render_detailed_table(folder, specs)
      anchor = folder.gsub(/[^a-zA-Z0-9]/, "_")
      sorted_specs = specs.sort_by { |e| e["file_path"] }

      path_counts = sorted_specs.each_with_object(Hash.new(0)) { |e, h| h[e["file_path"]] += 1 }
      seen_paths = Hash.new(0)

      rows = sorted_specs.map do |e|
        status_badge = e["status"] == "passed" ? "badge-passed" : "badge-failed"
        path = e["file_path"]
        file_name = File.basename(path)

        path_cell = if seen_paths[path].zero?
                      seen_paths[path] = 1
                      "<td rowspan=\"#{path_counts[path]}\" class=\"align-middle fw-semibold border-end\">#{file_name}</td>"
                    else
                      ""
                    end

        <<-HTML
        <tr>
          #{path_cell}
          <td>#{e["full_description"]} <span class="text-muted small">:#{e["line_number"]}</span></td>
          <td>#{e["run_time"].round(3)}s</td>
          <td><span class="badge #{status_badge}">#{e["status"].upcase}</span></td>
        </tr>
        HTML
      end.join

      <<~HTML
        <span class="anchor-offset" id="#{anchor}"></span>
        <div class="table-container">
          <div class="d-flex justify-content-between align-items-center mb-3">
            <h3>Folder: #{folder}</h3>
            <a href="#folders-table" class="btn btn-outline-primary btn-sm">↑ Back to Folders</a>
          </div>
          <table class="table table-bordered table-sm">
            <thead class="table-light">
              <tr><th>File Name</th><th>Description & Line</th><th>Time</th><th>Status</th></tr>
            </thead>
            <tbody>#{rows}</tbody>
          </table>
        </div>
      HTML
    end

    def generate_failed_report
      sorted_failures = failed_examples.sort_by { |e| e["file_path"] }
      path_counts = sorted_failures.each_with_object(Hash.new(0)) { |e, h| h[e["file_path"]] += 1 }
      seen_paths = Hash.new(0)

      rows = sorted_failures.map do |e|
        path = e["file_path"]
        file_name = File.basename(path)
        path_cell = if seen_paths[path].zero?
                      seen_paths[path] = 1
                      "<td rowspan=\"#{path_counts[path]}\" class=\"align-middle fw-semibold\">#{file_name}</td>"
                    else
                      ""
                    end

        <<-HTML
        <tr>
          #{path_cell}
          <td><b>#{e["full_description"]}</b> <span class="text-muted small">:#{e["line_number"]}</span></td>
          <td class="text-danger">#{e["exception"]["message"]}</td>
        </tr>
        HTML
      end.join

      # Prepare template variable
      @failed_rows = rows

      # Render ERB template
      template_path = File.join(__dir__, "templates", "failed_report.html.erb")
      template = ERB.new(File.read(template_path))
      html = template.result(binding)

      output_path = File.join(artifact_path, "rspec_failed_report.html")
      File.write(output_path, html)
    end
  end
end
