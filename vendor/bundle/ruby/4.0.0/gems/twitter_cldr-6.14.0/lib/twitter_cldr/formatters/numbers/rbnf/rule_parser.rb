# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    module Rbnf

      class RuleParser < TwitterCldr::Parsers::Parser

        private

        def do_parse(options)
          @locale = options.fetch(:locale, TwitterCldr.locale)
          switch([])
        end

        def switch(list)
          send(current_token.type, list)
        end

        def equals(list)
          contents = descriptor(current_token)
          list << Substitution.new(:equals, contents, 2)
          next_token(:equals)
          switch(list)
        end

        def left_arrow(list)
          contents = descriptor(current_token)
          list << Substitution.new(:left_arrow, contents, 2)
          next_token(:left_arrow)
          switch(list)
        end

        def right_arrow(list)
          contents = descriptor(current_token)
          sub = Substitution.new(:right_arrow, contents, 2)
          next_token(:right_arrow)

          # handle >>> case
          if current_token.type == :right_arrow
            sub.length += 1
            next_token(:right_arrow)
          end

          list << sub
          switch(list)
        end

        def plural(list)
          sub = Plural.from_string(
            @locale, current_token.value
          )

          list << sub
          next_token(:plural)
          switch(list)
        end

        def decimal(list)
          add_and_advance(list)
        end

        def plaintext(list)
          add_and_advance(list)
        end

        def open_bracket(list)
          add_and_advance(list)
        end

        def close_bracket(list)
          add_and_advance(list)
        end

        def semicolon(list)
          list
        end

        def add_and_advance(list)
          list << current_token
          next_token(current_token.type)
          switch(list)
        end

        def descriptor(token)
          next_token(token.type)
          contents = []
          until current_token.type == token.type
            contents << current_token
            next_token(current_token.type)
          end
          contents
        end

      end
    end
  end
end
