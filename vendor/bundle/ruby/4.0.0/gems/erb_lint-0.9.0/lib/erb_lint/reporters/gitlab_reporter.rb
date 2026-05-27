# frozen_string_literal: true

require "json"

module ERBLint
  module Reporters
    class GitlabReporter < Reporter
      def preview; end

      def show
        puts formatted_data
      end

      private

      def formatted_data
        formatted_files.to_json
      end

      def formatted_files
        processed_files.flat_map do |filename, offenses|
          formatted_offenses(filename, offenses)
        end
      end

      def formatted_offenses(filename, offenses)
        offenses.map do |offense|
          format_offense(filename, offense)
        end
      end

      def format_offense(filename, offense)
        {
          description: offense.message,
          check_name: offense.simple_name,
          fingerprint: generate_fingerprint(filename, offense),
          severity: offense.severity,
          location: {
            path: filename,
            lines: {
              begin: offense.line_number,
              end: offense.last_line,
            },
          },
        }
      end

      def generate_fingerprint(filename, offense)
        Digest::MD5.hexdigest(
          "#{offense.simple_name}@#{filename}:#{offense.line_number}:#{offense.last_line}",
        )
      end
    end
  end
end
