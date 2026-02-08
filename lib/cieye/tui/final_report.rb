# frozen_string_literal: true

require "lipgloss"

module Cieye
  class Tui
    # Output of failed specs and logs
    class FinalReport
      attr_reader :theme

      def initialize(theme)
        @theme = theme
      end

      def render(store, width)
        sections = []
        sections << divider(width)

        if store.failed_specs.any?
          sections << theme.failed.render("❌ FAILED SPECS")
          sections << render_failed_specs_table(store.failed_specs)
        else
          sections << theme.passed.render("✅ ALL TESTS PASSED!")
        end

        elapsed = (Time.now - store.start_time).to_i
        sections << "⏱️  Total time: #{elapsed / 60}m #{elapsed % 60}s"

        if store.current_logs.any?
          sections << "\n📋 SYSTEM MESSAGES"
          sections << render_final_logs_table(store.current_logs)
        end

        sections.join("\n\n")
      end

      private

      def divider(width)
        theme.header.render(" " * width)
      end

      def render_failed_specs_table(failed_specs)
        rows = failed_specs.map { |spec| [theme.failed.render("●"), spec] }

        Lipgloss::Table.new.rows(rows).border(:rounded).render
      end

      def render_final_logs_table(logs)
        sorted_logs = logs.sort_by { |_, d| [-d[:count], d[:level]] }.first(20)
        headers = %w[TYPE COUNT MESSAGE].map { |h| theme.header.render(h) }
        rows = sorted_logs.map do |msg, data|
          [level_tag(data[:level]), data[:count].to_s.rjust(3), truncate(msg, 65)]
        end

        Lipgloss::Table.new.headers(headers).rows(rows).border(:rounded).render
      end

      def level_tag(level)
        case level.to_s.downcase
        when "error"
          theme.tag_error.render("ERROR")
        when "warn", "warning"
          theme.tag_warn.render("WARN ")
        else
          theme.tag_log.render("LOG  ")
        end
      end

      def truncate(str, limit)
        s = str.to_s
        s.length <= limit ? s : "...#{s[-(limit - 3)..]}"
      end
    end
  end
end
