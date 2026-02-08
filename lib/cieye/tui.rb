# frozen_string_literal: true

require "lipgloss"
require "io/console"

require_relative "tui/theme"
require_relative "tui/progress_bar"
require_relative "tui/summary_table"
require_relative "tui/worker_table"
require_relative "tui/log_table"
require_relative "tui/final_report"

module Cieye
  class Tui
    attr_reader :spinner_frames,
                :theme,
                :summary_table,
                :worker_table,
                :log_table,
                :final_report

    attr_accessor :spinner_index

    def initialize(_worker_count)
      # @worker_count = worker_count.to_i
      # @spinner_frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
      # @spinner_index = 0
      # setup_styles

      @theme          = Theme.new
      @summary_table  = SummaryTable.new(theme)
      @worker_table   = WorkerTable.new(theme)
      @log_table      = LogTable.new(theme)
      @final_report   = FinalReport.new(theme)

      @spinner_frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
      @spinner_index  = 0
    end

    # def setup_styles
    #   purple = "#7D56F4"
    #   @style = {
    #     title: Lipgloss::Style.new.bold(true).foreground(purple).margin(1, 0),
    #     header: Lipgloss::Style.new.bold(true).foreground("#FAFAFA").background("#874BFD").padding(0, 1),
    #     worker_id: Lipgloss::Style.new.foreground("#00D7FF").bold(true),
    #     passed: Lipgloss::Style.new.foreground("#00FF00"),
    #     failed: Lipgloss::Style.new.foreground("#FF0000"),
    #     pending: Lipgloss::Style.new.foreground("#FFFF00"),
    #     file: Lipgloss::Style.new.foreground("#808080").italic(true),
    #     summary_box: Lipgloss::Style.new.border(:rounded).border_foreground("#874BFD").padding(0, 1).margin(0, 0),
    #     tag_log: Lipgloss::Style.new.foreground("#FFFFFF").background("#0000FF").bold(true).padding(0, 1),
    #     tag_warn: Lipgloss::Style.new.foreground("#FFFFFF").background("#FFA500").bold(true).padding(0, 1),
    #     tag_error: Lipgloss::Style.new.foreground("#FFFFFF").background("#FF0000").bold(true).padding(0, 1),
    #     spinner: Lipgloss::Style.new.foreground("#00D7FF").bold(true)
    #   }
    # end

    def screen_setup
      # Switch to alternate screen buffer and hide cursor
      print "\e[?1049h\e[?25l\e[2J\e[H"
      puts theme.title.render("🔥 RSPEC PARALLEL PIPELINE MONITOR")
      puts ""
      $stdout.flush
    end

    def screen_restore
      # Switch back to main screen
      print "\e[?25h\e[?1049l"
      $stdout.flush
    end

    def render(store)
      width   = terminal_width
      output  = frame(store, width)
      print "\e[H\e[3B\e[J"
      print output
      $stdout.flush
    end

    def frame(store, width)
      [
        summary_table.render(store),
        worker_table.render(store),
        log_table.render("⚠️ ERRORS / WARNINGS", store.debug_logs, width),
        log_table.render("📋 INFO", store.info_logs.first(5), width),
        render_footer(store.start_time)
      ].reject(&:empty?).join("\n\n")
    end

    def finalize(store)
      screen_restore
      width = terminal_width

      puts theme.title.render("🔥 RSPEC PARALLEL PIPELINE MONITOR")
      puts ""
      puts frame(store, width)
      puts ""

      puts final_report.render(store, width)
      $stdout.flush
    end

    # def frame(store)
    #   current_workers = store.current_workers
    #   current_logs    = store.current_logs
    #   lines           = []

    #   # 1. Summary box
    #   lines << render_summary_box(current_workers, store.start_time)
    #   lines << ""

    #   # 2. Worker table
    #   lines << render_worker_table(current_workers)
    #   lines << ""

    #   # 3. Critical logs (errors and warnings)
    #   critical_logs = current_logs.select { |_, data| %w[error warning].include?(data[:level]) }
    #   if critical_logs.any?
    #     lines << render_critical_logs(critical_logs)
    #     lines << ""
    #   end

    #   # 4. Regular logs preview
    #   regular_logs = current_logs.reject { |_, data| %w[error warning].include?(data[:level]) }
    #   if regular_logs.any?
    #     lines << render_live_logs(regular_logs)
    #     lines << ""
    #   end

    #   # 5. Footer with spinner
    #   lines << render_footer(store.start_time)

    #   lines.join("\n")
    # end

    # def render_final_report(store)
    #   failed  = store.failed_specs
    #   logs    = store.current_logs
    #   elapsed = (Time.now - store.start_time).to_i
    #   minutes = elapsed / 60
    #   seconds = elapsed % 60

    #   puts "\n#{"=" * 80}"

    #   if failed.any?
    #     puts theme.failed.render("❌ FAILED SPECS: #{failed.count}")
    #     puts ""
    #     failed.each { |spec| puts "  • #{spec}" }
    #   else
    #     puts theme.passed.render("✅ ALL TESTS PASSED!")
    #   end

    #   puts ""
    #   puts "⏱️  Total time: #{minutes}m #{seconds}s"

    #   if logs.any?
    #     puts ""
    #     puts "📋 SYSTEM MESSAGES SUMMARY (#{logs.size} unique):"
    #     puts "-" * 80

    #     logs.sort_by { |_, d| [-d[:count], d[:level]] }.first(20).each do |msg, data|
    #       truncated = msg.length > 100 ? "#{msg[0..97]}..." : msg
    #       puts "  #{render_level_tag(data[:level])} (x#{data[:count].to_s.rjust(3)}) #{truncated}"
    #     end
    #   end

    #   puts "#{"=" * 80}\n"
    #   $stdout.flush
    # end

    # def render(store)
    #   output = frame(store)
    #   # Go to home, move down 3 lines, clear to end
    #   print "\e[H\e[3B\e[J"
    #   print output
    #   $stdout.flush
    # end

    # def finalize(store)
    #   screen_restore

    #   # Print the title, final state frame, and the report
    #   puts style[:title].render("🔥 RSPEC PARALLEL PIPELINE MONITOR")
    #   puts ""
    #   puts frame(store)
    #   puts ""
    #   render_final_report(store)
    #   $stdout.flush
    # end

    private

    def terminal_width
      IO.console ? IO.console.winsize[1] : 80
    end

    # def render_summary_box(workers, start_time)
    #   total_passed = 0
    #   total_failed = 0
    #   total_pending = 0
    #   total_progress = 0.0

    #   workers.each do |_, stats|
    #     total_passed += stats[:passed]
    #     total_failed += stats[:failed]
    #     total_pending += stats[:pending]
    #     total_progress += stats[:percent] if stats[:active]
    #   end

    #   active_workers = workers.values.count { |w| w[:active] }
    #   avg_progress = active_workers > 0 ? (total_progress / active_workers) : 0.0

    #   elapsed = (Time.now - start_time).to_i
    #   minutes = elapsed / 60
    #   seconds = elapsed % 60

    #   summary_content = [
    #     "#{style[:passed].render("✅ #{total_passed}")}  #{style[:failed].render("❌ #{total_failed}")}  #{style[:pending].render("⏸️  #{total_pending}")}",
    #     "",
    #     "Overall Progress: #{draw_bar(avg_progress)} #{(avg_progress * 100).round(1)}%",
    #     "⏱️  Running: #{minutes}m #{seconds}s"
    #   ].join("\n")

    #   style[:summary_box].render(summary_content)
    # end

    # def render_worker_table(workers)
    #   rows = workers.sort_by { |id, _| id.to_i }.map do |id, stats|
    #     [
    #       style[:worker_id].render("Worker ##{id}"),
    #       draw_bar(stats[:percent]),
    #       style[:passed].render("🟢 #{stats[:passed]}"),
    #       style[:failed].render("🔴 #{stats[:failed]}"),
    #       style[:pending].render("⏸🟡  #{stats[:pending]}"),
    #       style[:file].render(left_truncate(stats[:file], 35))
    #     ]
    #   end

    #   headers = ["ID", "PROGRESS", "PASS", "FAIL", "PEND", "CURRENT SPEC"].map { |h| style[:header].render(h) }

    #   Lipgloss::Table.new.headers(headers).rows(rows).border(:rounded).render
    # end

    # def render_critical_logs(critical_logs)
    #   output = []
    #   output << Lipgloss::Style.new.bold(true).foreground("#FF0000").render("⚠️  ERRORS & WARNINGS")

    #   sorted_logs = critical_logs.sort_by do |msg, data|
    #     priority = data[:level] == "error" ? 0 : 1
    #     [priority, -data[:count]]
    #   end

    #   log_rows = sorted_logs.map do |msg, data|
    #     [render_level_tag(data[:level]), "x#{data[:count]}", left_truncate(msg, 80)]
    #   end

    #   log_headers = %w[TYPE COUNT MESSAGE].map { |h| style[:header].render(h) }
    #   output << Lipgloss::Table.new.headers(log_headers).rows(log_rows).border(:rounded).render
    #   output.join("\n")
    # end

    # def render_live_logs(regular_logs)
    #   output = []
    #   output << Lipgloss::Style.new.bold(true).render("📋 LIVE LOG PREVIEW (Last 5 unique messages)")

    #   sorted_logs = regular_logs.sort_by { |msg, data| -data[:count] }
    #   log_rows = sorted_logs.first(5).map do |msg, data|
    #     [render_level_tag(data[:level]), "x#{data[:count]}", left_truncate(msg, 80)]
    #   end

    #   log_headers = %w[TYPE COUNT MESSAGE].map { |h| style[:header].render(h) }
    #   output << Lipgloss::Table.new.headers(log_headers).rows(log_rows).border(:rounded).render
    #   output.join("\n")
    # end

    def render_level_tag(level)
      case level
      when "error"   then theme.tag_error.render("ERROR")
      when "warning" then theme.tag_warn.render("WARN ")
      else                theme.tag_log.render("LOG  ")
      end
    end

    def render_footer(start_time)
      self.spinner_index = (spinner_index + 1) % spinner_frames.length
      spinner_char = theme.spinner.render(spinner_frames[spinner_index])
      elapsed = (Time.now - start_time).to_i
      "#{spinner_char} Pipeline Active... | Elapsed: #{elapsed}s | Press CTRL+C to abort."
    end

    # def draw_bar(pct)
    #   width = 20
    #   filled = [(pct * width).to_i, width].min
    #   "█" * filled + "░" * (width - filled)
    # end

    # def left_truncate(str, limit)
    #   return str if str.to_s.length <= limit

    #   "..." + str.to_s[-(limit - 3)..-1]
    # end
  end
end
