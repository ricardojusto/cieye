# frozen_string_literal: true

require "lipgloss"

module Cieye
  class Tui
    # Table to display aggregated log messages and their counts
    class LogTable
      TABLE_HEADERS = %w[LEVEL COUNT MESSAGE].freeze
      SEVERITY_WEIGHT = {
        "error" => 3,
        "warn" => 2,
        "log" => 1,
        "info" => 1
      }.freeze

      attr_reader :theme

      def initialize(theme)
        @theme = theme
      end

      def render(title, logs, width)
        return "" if logs.empty?

        headers = TABLE_HEADERS.map { |h| theme.header.render(h) }
        rows    = logs.map { |msg, data| render_row(msg, data, width) }
        content = Lipgloss::Table.new.headers(headers).rows(rows).border(:rounded).width(width).render

        "#{Lipgloss::Style.new.bold(true).render(title)}\n#{content}"
      end

      private

      def severity_weight(level)
        SEVERITY_WEIGHT[level.to_s.downcase] || 0
      end

      def render_row(msg, data, width)
        msg_limit = width - 25 # space between borders
        msg_trunc = msg.length > msg_limit ? "#{msg[0..msg_limit - 3]}..." : msg

        [level_tag(data[:level]), data[:count].to_s, msg_trunc]
      end

      def level_tag(level)
        case level.to_s.downcase
        when "error"
          theme.tag_error.render("ERROR")
        when "warn"
          theme.tag_warn.render("WARN")
        else
          theme.tag_log.render("LOG")
        end
      end
    end
  end
end
