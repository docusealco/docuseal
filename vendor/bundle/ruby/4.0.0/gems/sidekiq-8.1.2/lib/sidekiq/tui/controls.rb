module Sidekiq
  class TUI
    module Controls
      # Defines data for input handling and for displaying controls.
      # :code is the key code for input handling.
      # :display and :description are shown in the controls area, with different
      #   styling between them. If :display is omitted, :code is displayed instead.
      # :action is a lambda to execute when the control is triggered.
      # :refresh means the action requires immediate refreshing of data
      #
      # Conventions: dangerous/irreversible actions should use UPPERCASE codes.
      # The Shift button means "I'm sure".
      GLOBAL = [
        {code: "?", display: "?", description: "Help", action: ->(tui, tab) { tui.show_help }},
        {code: "left", display: "←/→", description: "Select Tab", action: ->(tui, tab) { tui.navigate(:left) }, refresh: true},
        {code: "right", action: ->(tui, tab) { tui.navigate(:right) }, refresh: true},
        {code: "q", description: "Quit", action: ->(tui, tab) { :quit }},
        {code: "c", modifiers: ["ctrl"], action: ->(tui, tab) { :quit }}
      ].freeze

      SHARED = {
        pageable: [
          {code: "h", display: "h/l", description: "Prev/Next Page",
           action: ->(tui, tab) { tab.prev_page }, refresh: true},
          {code: "l", action: ->(tui, tab) { tab.next_page }, refresh: true}
        ],
        selectable: [
          {code: "k", display: "j/k", description: "Prev/Next Row",
           action: ->(tui, tab) { tab.navigate_row(:up) }},
          {code: "j", action: ->(tui, tab) { tab.navigate_row(:down) }},
          {code: "x", description: "Select", action: ->(tui, tab) { tab.toggle_select }},
          {code: "A", modifiers: ["shift"], display: "A", description: "Select All",
           action: ->(tui, tab) { tab.toggle_select(:all) }}
        ],
        filterable: [
          {code: "/", display: "/", description: "Filter", action: ->(tui, tab) { tab.start_filtering }},
          {code: "backspace", action: ->(tui, tab) { tab.remove_last_char_from_filter }, refresh: true},
          {code: "enter", action: ->(tui, tab) { tab.stop_filtering }, refresh: true},
          {code: "esc", action: ->(tui, tab) { tab.stop_and_clear_filtering }, refresh: true}
        ]
      }.freeze

      # Returns an array of symbols for functionality which this tab implements
      def features
        []
      end

      def controls
        GLOBAL + SHARED.slice(*features).values.flatten
      end
    end
  end
end
