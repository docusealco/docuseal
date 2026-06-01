# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Conversions

      SideMatch = Struct.new(:before_offset, :key_offset, :after_offset, :captures) do
        def start
          key_offset.first
        end

        def stop
          key_offset.last
        end
      end

      class Side
        attr_reader :before_context, :key
        attr_reader :after_context, :cursor_offset

        def initialize(before_context, key, after_context, cursor_offset)
          @before_context = before_context
          @key = key
          @after_context = after_context
          @cursor_offset = cursor_offset
        end

        def match(cursor)
          if before_match = match_before(cursor)
            if key_match = match_key(cursor, before_match)
              if after_match = match_after(cursor, key_match)
                SideMatch.new(
                  before_match.offset(0),
                  key_match.offset(0),
                  after_match.offset(0),
                  before_match.captures +
                    key_match.captures +
                    after_match.captures
                )
              end
            end
          end
        end

        def match_before(cursor)
          cursor.text.scan(before_context_regexp) do
            match = Regexp.last_match
            if match.end(0) >= cursor.position && match.begin(0) <= cursor.position
              return match
            end
          end
          nil
        end

        def match_key(cursor, before_match)
          if match = key_regexp.match(cursor.text, before_match.end(0))
            match if match.begin(0) == before_match.end(0)
          end
        end

        def match_after(cursor, key_match)
          if match = after_context_regexp.match(cursor.text, key_match.end(0))
            match if match.begin(0) == key_match.end(0)
          end
        end

        def has_codepoints?
          if first_elem = key_u_regexp.elements.first
            first_elem.respond_to?(:codepoints) &&
              !first_elem.codepoints.empty?
          else
            false
          end
        end

        def codepoints
          if first_elem = key_u_regexp.elements.first
            first_elem.codepoints
          else
            []
          end
        end

        private

        def before_context_regexp
          @before_context_regexp ||= compile_regexp(before_context).to_regexp
        end

        def key_u_regexp
          @key_u_regexp ||= compile_regexp(Rule.regexp_token_string(key))
        end

        def key_regexp
          @key_regexp ||= key_u_regexp.to_regexp
        end

        def after_context_regexp
          @after_context_regexp ||= compile_regexp(after_context).to_regexp
        end

        # This is a pretty big hack. The problem we're trying to solve here
        # is that regular negated character classes don't match the ends of
        # strings. CLDR's transform rules expect the after context to match
        # the end of a string, since, in a sense, "nothing" is always part
        # of a negated character class. In other words, "I want to match on
        # anything but these specific characters" should also include _no_
        # characters. Accordingly, this function adds "\z" to the ends of
        # negated character classes. Hopefully this works for all cases.
        def compile_regexp(regexp_str)
          TwitterCldr::Shared::UnicodeRegex.compile(regexp_str).tap do |re|
            re.elements.replace(
              re.elements.flat_map do |element|
                new_elem = case element.type
                when :character_class
                  if element.negated?
                    repl = TwitterCldr::Shared::UnicodeRegex.compile(
                      "(?:#{element.to_regexp_str[3..-2]}|\\z)"
                    )

                    repl.elements
                  end
                end

                new_elem || element
              end
            )
          end
        end

      end

    end
  end
end
