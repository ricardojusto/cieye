# frozen_string_literal: true

module Cieye
  class Tui
    # Progress bar for the TUI
    class ProgressBar
      def self.render(percent, width: 15)
        filled_length = [(percent * width).to_i, width].min
        empty_length  = [width - filled_length, 0].max

        "█" * filled_length + "░" * empty_length
      end
    end
  end
end
