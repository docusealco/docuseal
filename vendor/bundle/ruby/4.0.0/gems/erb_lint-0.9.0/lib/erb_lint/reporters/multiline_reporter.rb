# frozen_string_literal: true

require_relative "compact_reporter"

module ERBLint
  module Reporters
    class MultilineReporter < CompactReporter
      private

      def format_offense(filename, offense)
        details = "#{offense.message}#{Rainbow(" (not autocorrected)").red if autocorrect}"
        if show_linter_names
          details = "[#{offense.simple_name}] " + details
        end

        <<~EOF

          #{details}
          In file: #{filename}:#{offense.line_number}
        EOF
      end

      def footer
        puts
      end
    end
  end
end
