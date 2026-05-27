# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class TOML < RegexLexer
      title "TOML"
      desc 'the TOML configuration format (https://github.com/toml-lang/toml)'
      tag 'toml'

      filenames '*.toml', 'Pipfile', 'poetry.lock'
      mimetypes 'text/x-toml'

      state :root do
        mixin :whitespace

        mixin :key

        rule %r/(=)(\s*)/ do
          groups Operator, Text::Whitespace
          push :value
        end

        rule %r/\[\[?/, Keyword, :table_key
      end

      state :key do
        rule %r/[A-Za-z0-9_-]+/, Name

        rule %r/"/, Str, :dq
        rule %r/'/, Str, :sq
        rule %r/\./, Punctuation
      end

      state :table_key do
        rule %r/[A-Za-z0-9_-]+/, Name

        rule %r/"/, Str, :dq
        rule %r/'/, Str, :sq
        rule %r/\./, Keyword
        rule %r/\]\]?/, Keyword, :pop!
        rule %r/[ \t]+/, Text::Whitespace
      end

      state :value do
        rule %r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, Literal::Date, :pop!
        rule %r/\d\d:\d\d:\d\d(\.\d+)?/, Literal::Date, :pop!
        rule %r/[+-]?\d+(?:_\d+)*\.\d+(?:_\d+)*(?:[eE][+-]?\d+(?:_\d+)*)?/, Num::Float, :pop!
        rule %r/[+-]?\d+(?:_\d+)*[eE][+-]?\d+(?:_\d+)*/, Num::Float, :pop!
        rule %r/[+-]?(?:nan|inf)/, Num::Float, :pop!
        rule %r/0x\h+(?:_\h+)*/, Num::Hex, :pop!
        rule %r/0o[0-7]+(?:_[0-7]+)*/, Num::Oct, :pop!
        rule %r/0b[01]+(?:_[01]+)*/, Num::Bin, :pop!
        rule %r/[+-]?\d+(?:_\d+)*/, Num::Integer, :pop!

        rule %r/"""/, Str, [:pop!, :mdq]
        rule %r/"/, Str, [:pop!, :dq]
        rule %r/'''/, Str, [:pop!, :msq]
        rule %r/'/, Str, [:pop!, :sq]

        rule %r/(true|false)/, Keyword::Constant, :pop!
        rule %r/\[/, Punctuation, [:pop!, :array]
        rule %r/\{/, Punctuation, [:pop!, :inline]
      end

      state :dq do
        rule %r/"/, Str, :pop!
        rule %r/\n/, Error, :pop!
        mixin :esc_str
        rule %r/[^\\"\n]+/, Str
      end

      state :mdq do
        rule %r/"""/, Str, :pop!
        mixin :esc_str
        rule %r/[^\\"]+/, Str
        rule %r/"+/, Str
      end

      state :sq do
        rule %r/'/, Str, :pop!
        rule %r/\n/, Error, :pop!
        rule %r/[^'\n]+/, Str
      end

      state :msq do
        rule %r/'''/, Str, :pop!
        rule %r/[^']+/, Str
        rule %r/'+/, Str
      end

      state :esc_str do
        rule %r/\\[0t\tn\n "\\r]/, Str::Escape
      end

      state :array do
        mixin :whitespace
        rule %r/,/, Punctuation

        rule %r/\]/, Punctuation, :pop!

        rule %r//, Token, :value
      end

      state :inline do
        rule %r/[ \t]+/, Text::Whitespace

        mixin :key
        rule %r/(=)(\s*)/ do
          groups Punctuation, Text::Whitespace
          push :value
        end

        rule %r/,/, Punctuation
        rule %r/\}/, Punctuation, :pop!
      end

      state :whitespace do
        rule %r/\s+/, Text
        rule %r/#.*?$/, Comment
      end
    end
  end
end
