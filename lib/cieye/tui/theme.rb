# frozen_string_literal: true

require "lipgloss"

module Cieye
  class Tui
    # Theme settings for the TUI
    class Theme
      BRAND_PURPLE  = "#7D56F4"
      BRAND_VIOLET  = "#874BFD"
      CYAN          = "#00D7FF"
      WHITE         = "#FAFAFA"
      GRAY          = "#808080"
      SUCCESS_GREEN = "#00FF00"
      ERROR_RED     = "#FF0000"
      WARN_ORANGE   = "#FFA500"
      WAIT_YELLOW   = "#FFFF00"
      LOG_BLUE      = "#0000FF"

      attr_reader :title,
                  :header,
                  :worker_id,
                  :passed,
                  :failed,
                  :pending,
                  :file,
                  :summary_box,
                  :tag_log,
                  :tag_warn,
                  :tag_error,
                  :spinner

      def initialize
        branding_styles
        status_styles
        tag_styles
        component_styles
      end

      private

      def branding_styles
        @title        = Lipgloss::Style.new.bold(true).foreground(BRAND_PURPLE).margin(1, 0)
        @header       = Lipgloss::Style.new.bold(true).foreground(WHITE).background(BRAND_VIOLET).padding(0, 1)
        @worker_id    = Lipgloss::Style.new.foreground(CYAN).bold(true)
      end

      def status_styles
        @passed       = Lipgloss::Style.new.foreground(SUCCESS_GREEN)
        @failed       = Lipgloss::Style.new.foreground(ERROR_RED)
        @pending      = Lipgloss::Style.new.foreground(WAIT_YELLOW)
      end

      def tag_styles
        @tag_log      = Lipgloss::Style.new.foreground(WHITE).background(LOG_BLUE).bold(true).padding(0, 1)
        @tag_warn     = Lipgloss::Style.new.foreground(WHITE).background(WARN_ORANGE).bold(true).padding(0, 1)
        @tag_error    = Lipgloss::Style.new.foreground(WHITE).background(ERROR_RED).bold(true).padding(0, 1)
      end

      def component_styles
        @file         = Lipgloss::Style.new.foreground(GRAY).italic(true)
        @summary_box  = Lipgloss::Style.new.border(:rounded).border_foreground(BRAND_VIOLET).padding(0, 1).margin(0, 0)
        @spinner      = Lipgloss::Style.new.foreground(CYAN).bold(true)
      end
    end
  end
end
