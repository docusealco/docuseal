# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class IecST < RegexLexer
      tag 'iecst'
      title "IEC 61131-3 Structured Text"
      desc 'Structured text is a programming language for PLCs (programmable logic controllers).'
      filenames '*.awl', '*.scl', '*.st'

      mimetypes 'text/x-iecst'

      def self.keywords
        blocks = %w(
          PROGRAM CONFIGURATION INITIAL_STEP INTERFACE FUNCTION_BLOCK FUNCTION ACTION TRANSITION
          TYPE STRUCT STEP NAMESPACE LIBRARY CHANNEL FOLDER RESOURCE
          VAR_ACCESS VAR_CONFIG VAR_EXTERNAL VAR_GLOBAL VAR_INPUT VAR_IN_OUT VAR_OUTPUT VAR_TEMP VAR
          CONST METHOD PROPERTY
          CASE FOR IF REPEAT WHILE
        )
        @keywords ||= Set.new %w(
          AT BEGIN BY CONSTANT CONTINUE DO ELSE ELSIF EXIT EXTENDS FROM GET GOTO IMPLEMENTS JMP
          NON_RETAIN OF PRIVATE PROTECTED PUBLIC RETAIN RETURN SET TASK THEN TO UNTIL USING WITH
          __CATCH __ENDTRY __FINALLY __TRY
        ) + blocks + blocks.map {|kw| "END_" + kw}
      end

      def self.types
        @types ||= Set.new %w(
          ANY ARRAY BOOL BYTE POINTER STRING
          DATE DATE_AND_TIME DT TIME TIME_OF_DAY TOD
          INT DINT LINT SINT UINT UDINT ULINT USINT
          WORD DWORD LWORD
          REAL LREAL
        )
      end

      def self.literals
        @literals ||= Set.new %w(TRUE FALSE NULL)
      end

      def self.operators
        @operators ||= Set.new %w(AND EQ EXPT GE GT LE LT MOD NE NOT OR XOR)
      end

      state :whitespace do
        # Spaces
        rule %r/\s+/m, Text
        # // Comments
        rule %r((//).*$\n?), Comment::Single
        # (* Comments *)
        rule %r(\(\*.*?\*\))m, Comment::Multiline
        # { Comments }
        rule %r(\{.*?\})m, Comment::Special
      end

      state :root do
        mixin :whitespace

        rule %r/'[^']+'/, Literal::String::Single
        rule %r/"[^"]+"/, Literal::String::Symbol
        rule %r/%[IQM][XBWDL][\d.]*|%[IQ][\d.]*/, Name::Variable::Magic
        rule %r/\b(?:D|DT|T|TOD)#[\d_shmd:]*/i, Literal::Date
        rule %r/\b(?:16#[\d_a-f]+|0x[\d_a-f]+)\b/i, Literal::Number::Hex
        rule %r/\b2#[01_]+/, Literal::Number::Bin
        rule %r/(?:\b\d+(?:\.\d*)?|\B\.\d+)(?:e[+-]?\d+)?/i, Literal::Number::Float
        rule %r/\b[\d.,_]+/, Literal::Number

        rule %r/\b[A-Z_]+\b/i do |m|
          name = m[0].upcase
          if self.class.keywords.include?(name)
            token Keyword
          elsif self.class.types.include?(name)
            token Keyword::Type
          elsif self.class.literals.include?(name)
            token Literal
          elsif self.class.operators.include?(name)
            token Operator
          else
            token Name
          end
        end

        rule %r/S?R?:?=>?|&&?|\*\*?|<[=>]?|>=?|[-:^\/+#]/, Operator
        rule %r/\b[a-z_]\w*(?=\s*\()/i, Name::Function
        rule %r/\b[a-z_]\w*\b/i, Name
        rule %r/[()\[\].,;]/, Punctuation
      end
    end
  end
end
