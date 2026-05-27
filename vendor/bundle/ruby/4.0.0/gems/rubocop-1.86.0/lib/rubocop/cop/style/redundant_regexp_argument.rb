# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies places where argument can be replaced from
      # a deterministic regexp to a string.
      #
      # @example
      #   # bad
      #   'foo'.byteindex(/f/)
      #   'foo'.byterindex(/f/)
      #   'foo'.gsub(/f/, 'x')
      #   'foo'.gsub!(/f/, 'x')
      #   'foo'.partition(/f/)
      #   'foo'.rpartition(/f/)
      #   'foo'.scan(/f/)
      #   'foo'.split(/f/)
      #   'foo'.start_with?(/f/)
      #   'foo'.sub(/f/, 'x')
      #   'foo'.sub!(/f/, 'x')
      #
      #   # good
      #   'foo'.byteindex('f')
      #   'foo'.byterindex('f')
      #   'foo'.gsub('f', 'x')
      #   'foo'.gsub!('f', 'x')
      #   'foo'.partition('f')
      #   'foo'.rpartition('f')
      #   'foo'.scan('f')
      #   'foo'.split('f')
      #   'foo'.start_with?('f')
      #   'foo'.sub('f', 'x')
      #   'foo'.sub!('f', 'x')
      class RedundantRegexpArgument < Base
        include StringLiteralsHelp
        extend AutoCorrector

        MSG = 'Use string `%<prefer>s` as argument instead of regexp `%<current>s`.'
        RESTRICT_ON_SEND = %i[
          byteindex byterindex gsub gsub! partition rpartition scan split start_with? sub sub!
        ].freeze
        DETERMINISTIC_REGEX = /\A(?:#{LITERAL_REGEX})+\Z/.freeze
        STR_SPECIAL_CHARS = %w[
          \a \c \C \e \f \M \n \" \' \\\\ \t \b \f \r \u \v \x \0 \1 \2 \3 \4 \5 \6 \7
        ].freeze

        def on_send(node)
          return unless (regexp_node = node.first_argument)
          return unless regexp_node.regexp_type?
          return if !regexp_node.regopt.children.empty? || regexp_node.content == ' '
          return unless determinist_regexp?(regexp_node)

          prefer = preferred_argument(regexp_node)
          message = format(MSG, prefer: prefer, current: regexp_node.source)

          add_offense(regexp_node, message: message) do |corrector|
            corrector.replace(regexp_node, prefer)
          end
        end
        alias on_csend on_send

        private

        def determinist_regexp?(regexp_node)
          DETERMINISTIC_REGEX.match?(regexp_node.source)
        end

        # rubocop:disable Metrics/MethodLength
        def preferred_argument(regexp_node)
          new_argument = replacement(regexp_node)

          if new_argument.include?('"')
            new_argument.gsub!("'", "\\\\'")
            new_argument.gsub!('\"', '"')
            quote = "'"
          elsif new_argument.include?("\\'")
            # Add a backslash before single quotes preceded by an even number of backslashes.
            # An even number (including zero) of backslashes before a quote means the quote itself
            # is not escaped.
            # Otherwise an odd number means the quote is already escaped so this doesn't touch it.
            new_argument.gsub!(/(?<!\\)((?:\\\\)*)'/) { "#{::Regexp.last_match(1)}\\'" }
            quote = "'"
          elsif new_argument.include?('\'')
            new_argument.gsub!("'", "\\\\'")
            quote = "'"
          elsif new_argument.include?('\\')
            quote = '"'
          else
            quote = enforce_double_quotes? ? '"' : "'"
          end

          "#{quote}#{new_argument}#{quote}"
        end
        # rubocop:enable Metrics/MethodLength

        def replacement(regexp_node)
          regexp_content = regexp_node.content
          stack = []
          chars = regexp_content.chars.each_with_object([]) do |char, strings|
            if stack.empty? && char == '\\'
              stack.push(char)
            else
              strings << "#{stack.pop}#{char}"
            end
          end
          chars.map do |char|
            char = char.dup
            char.delete!('\\') unless STR_SPECIAL_CHARS.include?(char)
            char
          end.join
        end
      end
    end
  end
end
