# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'json.rb'

    class JSON5 < JSON
      title 'JSON 5'
      tag 'json5'
      filenames '*.json5'
      mimetypes 'application/json5', 'application/x-json5'

      desc 'JSON 5 extension for JSON (json5.org)'

      append :whitespace do
        rule %r://.*$:, Comment

        # comments are non-nesting, so a single regex will do
        rule %r:/[*].*?[*]/:m, Comment
      end

      prepend :name do
        rule Javascript.id_regex, Name::Label
        rule %r/".*?"/, Name::Label
      end

      # comments can appear between keys and :, so we have to
      # manage our states a little more carefully
      append :object do
        rule %r/:/ do
          token Punctuation
          goto :object_value
        end
      end

      state :object_value do
        mixin :value
        rule %r/,/ do
          token Punctuation
          goto :object
        end

        rule %r/}/, Punctuation, :pop!
      end

      append :value do
        rule %r/'/, Str::Single, :sstring
      end

      state :sstring do
        rule %r/[^\\']+/, Str::Single
        rule %r/\\./m, Str::Escape
        rule %r/'/, Str::Single, :pop!
      end

      # can escape newlines
      append :string do
        rule %r/\\./m, Str::Escape
      end

      # override: numbers are very different in json5
      state :constants do
        rule %r/\b(?:true|false|null)\b/, Keyword::Constant
        rule %r/[+-]?\b(?:Infinity|NaN)\b/, Keyword::Constant
        rule %r/[+-]?0x\h+/i, Num::Hex

        rule %r/[+-.]?[0-9]+[.]?[0-9]?([eE][-]?[0-9]+)?/i, Num::Float
        rule %r/[+-]?\d+e[+-]?\d+/, Num::Integer
        rule %r/[+-]?(?:0|[1-9]\d*)(?:e[+-]?\d+)?/i, Num::Integer
      end
    end
  end
end
