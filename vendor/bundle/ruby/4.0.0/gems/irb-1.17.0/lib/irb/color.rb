# frozen_string_literal: true
require 'reline'
require 'prism'
require_relative 'ruby-lex'

module IRB # :nodoc:
  module Color
    CLEAR     = 0
    BOLD      = 1
    UNDERLINE = 4
    REVERSE   = 7
    BLACK     = 30
    RED       = 31
    GREEN     = 32
    YELLOW    = 33
    BLUE      = 34
    MAGENTA   = 35
    CYAN      = 36
    WHITE     = 37

    # Following pry's colors where possible
    TOKEN_SEQS = {
      KEYWORD_NIL:        [CYAN, BOLD],
      KEYWORD_SELF:       [CYAN, BOLD],
      KEYWORD_TRUE:       [CYAN, BOLD],
      KEYWORD_FALSE:      [CYAN, BOLD],
      KEYWORD___FILE__:   [CYAN, BOLD],
      KEYWORD___LINE__:   [CYAN, BOLD],
      KEYWORD___ENCODING__: [CYAN, BOLD],
      CHARACTER_LITERAL:  [BLUE, BOLD],
      BACK_REFERENCE:     [GREEN, BOLD],
      BACKTICK:           [RED, BOLD],
      COMMENT:            [BLUE, BOLD],
      EMBDOC_BEGIN:       [BLUE, BOLD],
      EMBDOC_LINE:        [BLUE, BOLD],
      EMBDOC_END:         [BLUE, BOLD],
      CONSTANT:           [BLUE, BOLD, UNDERLINE],
      EMBEXPR_BEGIN:      [RED],
      EMBEXPR_END:        [RED],
      EMBVAR:             [RED],
      FLOAT:              [MAGENTA, BOLD],
      GLOBAL_VARIABLE:    [GREEN, BOLD],
      HEREDOC_START:      [RED],
      HEREDOC_END:        [RED],
      FLOAT_IMAGINARY:    [BLUE, BOLD],
      INTEGER_IMAGINARY:  [BLUE, BOLD],
      FLOAT_RATIONAL_IMAGINARY:  [BLUE, BOLD],
      INTEGER_RATIONAL_IMAGINARY:  [BLUE, BOLD],
      INTEGER:            [BLUE, BOLD],
      INTEGER_RATIONAL:   [BLUE, BOLD],
      FLOAT_RATIONAL:     [BLUE, BOLD],
      KEYWORD_END:        [GREEN],
      KEYWORD_CLASS:      [GREEN],
      KEYWORD_MODULE:     [GREEN],
      KEYWORD_IF:         [GREEN],
      KEYWORD_IF_MODIFIER: [GREEN],
      KEYWORD_UNLESS_MODIFIER: [GREEN],
      KEYWORD_WHILE_MODIFIER: [GREEN],
      KEYWORD_UNTIL_MODIFIER: [GREEN],
      KEYWORD_RESCUE_MODIFIER: [GREEN],
      KEYWORD_THEN:       [GREEN],
      KEYWORD_UNLESS:     [GREEN],
      KEYWORD_ELSE:       [GREEN],
      KEYWORD_ELSIF:      [GREEN],
      KEYWORD_WHILE:      [GREEN],
      KEYWORD_UNTIL:      [GREEN],
      KEYWORD_CASE:       [GREEN],
      KEYWORD_WHEN:       [GREEN],
      KEYWORD_IN:         [GREEN],
      KEYWORD_DEF:        [GREEN],
      KEYWORD_DO:         [GREEN],
      KEYWORD_DO_LOOP:    [GREEN],
      KEYWORD_FOR:        [GREEN],
      KEYWORD_BEGIN:      [GREEN],
      KEYWORD_RESCUE:     [GREEN],
      KEYWORD_ENSURE:     [GREEN],
      KEYWORD_ALIAS:      [GREEN],
      KEYWORD_UNDEF:      [GREEN],
      KEYWORD_BEGIN_UPCASE: [GREEN],
      KEYWORD_END_UPCASE: [GREEN],
      KEYWORD_YIELD:      [GREEN],
      KEYWORD_REDO:       [GREEN],
      KEYWORD_RETRY:      [GREEN],
      KEYWORD_NEXT:       [GREEN],
      KEYWORD_BREAK:      [GREEN],
      KEYWORD_SUPER:      [GREEN],
      KEYWORD_RETURN:     [GREEN],
      KEYWORD_DEFINED:    [GREEN],
      KEYWORD_NOT:        [GREEN],
      KEYWORD_AND:        [GREEN],
      KEYWORD_OR:         [GREEN],
      LABEL:              [MAGENTA],
      LABEL_END:          [RED, BOLD],
      NUMBERED_REFERENCE: [GREEN, BOLD],
      PERCENT_UPPER_W:    [RED, BOLD],
      PERCENT_LOWER_W:    [RED, BOLD],
      PERCENT_LOWER_X:    [RED, BOLD],
      REGEXP_BEGIN:       [RED, BOLD],
      REGEXP_END:         [RED, BOLD],
      STRING_BEGIN:       [RED, BOLD],
      STRING_CONTENT:     [RED],
      STRING_END:         [RED, BOLD],
      __END__:            [GREEN],
      # tokens from syntax tree traversal
      method_name:        [BLUE, BOLD],
      symbol:             [YELLOW],
      # special colorization
      error:              [RED, REVERSE],
      const_env:          [CYAN, BOLD],
    }.transform_values do |styles|
      styles.map { |style| "\e[#{style}m" }.join
    end
    CLEAR_SEQ = "\e[#{CLEAR}m"
    private_constant :TOKEN_SEQS, :CLEAR_SEQ

    class << self
      def colorable?
        supported = $stdout.tty? && (/mswin|mingw/.match?(RUBY_PLATFORM) || (ENV.key?('TERM') && ENV['TERM'] != 'dumb'))

        # because ruby/debug also uses irb's color module selectively,
        # irb won't be activated in that case.
        if IRB.respond_to?(:conf)
          supported && !!IRB.conf.fetch(:USE_COLORIZE, true)
        else
          supported
        end
      end

      def inspect_colorable?(obj, seen: {}.compare_by_identity)
        case obj
        when String, Symbol, Regexp, Integer, Float, FalseClass, TrueClass, NilClass
          true
        when Hash
          without_circular_ref(obj, seen: seen) do
            obj.all? { |k, v| inspect_colorable?(k, seen: seen) && inspect_colorable?(v, seen: seen) }
          end
        when Array
          without_circular_ref(obj, seen: seen) do
            obj.all? { |o| inspect_colorable?(o, seen: seen) }
          end
        when Range
          inspect_colorable?(obj.begin, seen: seen) && inspect_colorable?(obj.end, seen: seen)
        when Module
          !obj.name.nil?
        else
          false
        end
      end

      def clear(colorable: colorable?)
        colorable ? CLEAR_SEQ : ''
      end

      def colorize(text, seq, colorable: colorable?)
        return text unless colorable
        seq = seq.map { |s| "\e[#{const_get(s)}m" }.join('')
        "#{seq}#{text}#{CLEAR_SEQ}"
      end

      # If `complete` is false (code is incomplete), this does not warn compile_error.
      # This option is needed to avoid warning a user when the compile_error is happening
      # because the input is not wrong but just incomplete.
      def colorize_code(code, complete: true, ignore_error: false, colorable: colorable?, local_variables: [])
        return code unless colorable

        result = Prism.parse_lex(code, scopes: [local_variables])

        # IRB::ColorPrinter skips colorizing syntax invalid fragments
        return Reline::Unicode.escape_for_print(code) if ignore_error && !result.success?

        errors = result.errors
        unless complete
          errors = errors.reject { |error| error.message =~ /\Aexpected a|unexpected end-of-input|unterminated/ }
        end

        prism_node, prism_tokens = result.value
        visitor = ColorizeVisitor.new
        prism_node.accept(visitor)

        error_tokens = errors.map { |e| [e.location.start_line, e.location.start_column, 0, e.location.end_line, e.location.end_column, :error, e.location.slice] }
        error_tokens.reject! { |t| t.last.match?(/\A\s*\z/) }
        tokens = prism_tokens.map { |t,| [t.location.start_line, t.location.start_column, 2, t.location.end_line, t.location.end_column, t.type, t.value] }
        tokens.pop if tokens.last&.[](5) == :EOF

        colored = +''
        line_index = 0
        col = 0
        lines = code.lines
        flush = -> next_line_index, next_col {
          return if next_line_index == line_index && next_col == col
          (line_index...[next_line_index, lines.size].min).each do |ln|
            colored << Reline::Unicode.escape_for_print(lines[line_index].byteslice(col..))
            line_index = ln + 1
            col = 0
          end
          unless col == next_col
            colored << Reline::Unicode.escape_for_print(lines[next_line_index].byteslice(col..next_col - 1))
          end
        }

        (visitor.tokens + tokens + error_tokens).sort.each do |start_line, start_column, _priority, end_line, end_column, type, value|
          next if start_line - 1 < line_index || (start_line - 1 == line_index && start_column < col)

          flush.call(start_line - 1, start_column)
          if type == :CONSTANT && value == 'ENV'
            color = TOKEN_SEQS[:const_env]
          elsif type == :__END__
            color = TOKEN_SEQS[type]
            end_line = start_line
            value = '__END__'
            end_column = start_column + 7
          else
            color = TOKEN_SEQS[type]
          end
          if color
            value.split(/(\n)/).each do |s|
              colored << (s == "\n" ? s : "#{color}#{Reline::Unicode.escape_for_print(s)}#{CLEAR_SEQ}")
            end
          else
            colored << value
          end
          line_index = end_line - 1
          col = end_column
        end
        flush.call lines.size, 0
        colored
      end

      class ColorizeVisitor < Prism::Visitor
        attr_reader :tokens
        def initialize
          @tokens = []
        end

        def dispatch(location, type)
          if location
            @tokens << [location.start_line, location.start_column, 1, location.end_line, location.end_column, type, location.slice]
          end
        end

        def visit_array_node(node)
          if node.opening&.match?(/\A%[iI]/)
            dispatch node.opening_loc, :symbol
            dispatch node.closing_loc, :symbol
          end
          super
        end

        def visit_def_node(node)
          dispatch node.name_loc, :method_name
          super
        end

        def visit_interpolated_symbol_node(node)
          dispatch node.opening_loc, :symbol
          node.parts.each do |part|
            case part
            when Prism::StringNode
              dispatch part.content_loc, :symbol
            when Prism::EmbeddedStatementsNode
              dispatch part.opening_loc, :symbol
              dispatch part.closing_loc, :symbol
            when Prism::EmbeddedVariableNode
              dispatch part.operator_loc, :symbol
            end
          end
          dispatch node.closing_loc, :symbol
          super
        end

        def visit_symbol_node(node)
          if (node.opening_loc.nil? && node.closing == ':') || node.closing&.match?(/\A['"]:\z/)
            # Colorize { symbol: 1 } and { 'symbol': 1 } as label
            dispatch node.location, :LABEL
          else
            dispatch node.opening_loc, :symbol
            dispatch node.value_loc, :symbol
            dispatch node.closing_loc, :symbol
          end
        end
      end

      private

      def without_circular_ref(obj, seen:, &block)
        return false if seen.key?(obj)
        seen[obj] = true
        block.call
      ensure
        seen.delete(obj)
      end
    end
  end
end
