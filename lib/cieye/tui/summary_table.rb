# frozen_string_literal: true

module Cieye
  class Tui
    # Summary of the spec stats and logs
    class SummaryTable
      attr_reader :theme

      def initialize(theme)
        @theme = theme
      end

      def render(store)
        stats   = store.summary_table_stats
        elapsed = [0, Time.now - store.start_time].max
        content = [
          render_counters(stats),
          "",
          render_progress_row(stats[:avg_progress]),
          render_timer(elapsed)
        ].join("\n")

        theme.summary_box.render(content)
      end

      private

      def render_counters(stats)
        [
          theme.passed.render("🟢 #{stats[:passed]}"),
          theme.failed.render("🔴 #{stats[:failed]}"),
          theme.pending.render("🟡 #{stats[:pending]}")
        ].join("  ")
      end

      def render_progress_row(avg_progress)
        bar = draw_bar(avg_progress)
        percentage = (avg_progress * 100).round(1)
        "Overall Progress: #{bar} #{percentage}%"
      end

      def render_timer(elapsed)
        minutes = elapsed.to_i / 60
        seconds = elapsed.to_i % 60
        "⏱️  Running: #{minutes}m #{seconds}s"
      end

      def draw_bar(pct)
        width = 20
        filled = [(pct * width).to_i, width].min
        "█" * filled + "░" * (width - filled)
      end
    end
  end
end
