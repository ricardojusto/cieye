# frozen_string_literal: true

require "lipgloss"

module Cieye
  class Tui
    # Table to display each worker progress
    class WorkerTable
      TABLE_HEADERS = ["ID", "PROGRESS", "%", "PASS", "FAIL", "PEND", "CURRENT SPEC"].freeze

      attr_reader :theme

      def initialize(theme)
        @theme = theme
      end

      def render(store)
        workers = store.current_workers
        headers = TABLE_HEADERS.map { |h| theme.header.render(h) }
        rows    = workers.sort_by { |id, _| id.to_i }.map { |id, data| render_row(id, data) }

        Lipgloss::Table.new.headers(headers).rows(rows).border(:rounded).render
      end

      private

      def render_row(id, data)
        [
          theme.worker_id.render("Worker #{id}"),
          ProgressBar.render(data[:percent]),
          "#{(data[:percent] * 100).round(0)}%",
          theme.passed.render("🟢 #{data[:passed]}"),
          theme.failed.render("🔴 #{data[:failed]}"),
          theme.pending.render("🟡 #{data[:pending]}"),
          theme.file.render(left_truncate(data[:file], 45))
        ]
      end

      def left_truncate(path, max_width)
        return path if path.length <= max_width

        "...#{path[-(max_width - 3)..]}"
      end
    end
  end
end
