# frozen_string_literal: true

require 'prism'

module IRB
  module NestingParser
    NestingElem = Struct.new(:pos, :event, :tok)

    class NestingVisitor < Prism::Visitor
      def initialize
        # Array of [column, priority(+1/-1), NestingElem(open) or nil(close)] per line.
        # priority is +1 for open, -1 for close so that close comes before open when sorted.
        # Example:
        #   if cond
        #   else
        #   end
        # `else` closes `if` at column 0 first and then opens `else` at column 0 next.
        @lines = []

        # Array of open heredoc NestingElem per line
        @heredocs = []
      end

      def nestings
        size = [@lines.size, @heredocs.size].max
        nesting = []
        size.times.map do |line_index|
          @lines[line_index]&.sort_by { |col, pri| [col, pri] }&.each do |col, pri, elem|
            if elem
              nesting << elem
            else
              nesting.pop
            end
          end
          @heredocs[line_index]&.sort_by { |elem| elem.pos[1] }&.reverse_each do |elem|
            nesting << elem
          end
          nesting.dup
        end
      end

      def heredoc_open(node)
        elem = NestingElem.new([node.location.start_line, node.location.start_column], :on_heredoc_beg, node.opening)
        (@heredocs[node.location.start_line - 1] ||= []) << elem
      end

      def open(line, column, elem)
        (@lines[line - 1] ||= []) << [column, +1, elem]
      end

      def close(line, column)
        (@lines[line - 1] ||= []) << [column, -1]
      end

      # Checks if a node (if, while, etc) is a modifier form that does not need `end` closing.
      # modifier node: `a if b`, non-modifier node: `if a; b; end`
      def modifier_node?(node, keyword_loc)
        !(keyword_loc && node.location.start_line == keyword_loc.start_line && node.location.start_column == keyword_loc.start_column)
      end

      def open_location(location, type, tok)
        open(location.start_line, location.start_column, NestingElem.new([location.start_line, location.start_column], type, tok))
      end

      def close_location(location)
        close(location.end_line, location.end_column)
      end

      def close_location_start(location)
        close(location.start_line, location.start_column)
      end

      def close_end_keyword_loc(node)
        close_location(node.end_keyword_loc) if node.end_keyword == 'end'
      end

      def close_closing_loc(node)
        close_location(node.closing_loc) if node.closing_loc && !node.closing.empty?
      end

      def visit_for_node(node)
        super
        open_location(node.location, :on_kw, 'for')
        close_end_keyword_loc(node)
      end

      def visit_while_node(node)
        super
        return if modifier_node?(node, node.keyword_loc)

        open_location(node.location, :on_kw, 'while')
        close_closing_loc(node)
      end

      def visit_until_node(node)
        super
        return if modifier_node?(node, node.keyword_loc)

        open_location(node.location, :on_kw, 'until')
        close_closing_loc(node)
      end

      def visit_if_node(node)
        super
        return if !node.if_keyword || modifier_node?(node, node.if_keyword_loc)

        open_location(node.location, :on_kw, node.if_keyword)
        if node.subsequent
          close_location_start(node.subsequent.location)
        else
          close_end_keyword_loc(node)
        end
      end

      def visit_unless_node(node)
        super
        return if modifier_node?(node, node.keyword_loc)

        open_location(node.location, :on_kw, 'unless')
        if node.else_clause
          close_location_start(node.else_clause.location)
        else
          close_end_keyword_loc(node)
        end
      end

      def visit_case_node(node)
        super
        open_location(node.location, :on_kw, 'case')
        if node.else_clause
          close_location_start(node.else_clause.location)
        else
          close_end_keyword_loc(node)
        end
      end
      alias visit_case_match_node visit_case_node

      def visit_when_node(node)
        super
        close_location_start(node.location)
        open_location(node.location, :on_kw, 'when')
      end

      def visit_in_node(node)
        super
        close_location_start(node.location)
        open_location(node.location, :on_kw, 'in')
      end

      def visit_else_node(node)
        super
        if node.else_keyword == 'else'
          open_location(node.location, :on_kw, 'else')
          close_end_keyword_loc(node)
        end
      end

      def visit_ensure_node(node)
        super
        return if modifier_node?(node, node.ensure_keyword_loc)

        close_location_start(node.location)
        open_location(node.location, :on_kw, 'ensure')
      end

      def visit_rescue_node(node)
        super
        return if modifier_node?(node, node.keyword_loc)

        close_location_start(node.location)
        open_location(node.location, :on_kw, 'rescue')
      end

      def visit_begin_node(node)
        super
        if node.begin_keyword
          open_location(node.location, :on_kw, 'begin')
          close_end_keyword_loc(node)
        end
      end

      def visit_block_node(node)
        super
        open_location(node.location, node.opening == '{' ? :on_lbrace : :on_kw, node.opening)
        close_closing_loc(node)
      end

      def visit_array_node(node)
        super
        type =
          case node.opening
          when nil
            # `x = 1, 2` doesn't have opening
            nil
          when '['
            :bracket
          when /\A%W/
            :on_words_beg
          when /\A%w/
            :on_qwords_beg
          when /\A%I/
            :on_symbols_beg
          when /\A%i/
            :on_qsymbols_beg
          end

        if type
          open_location(node.location, type, node.opening)
          close_closing_loc(node)
        end
      end

      def visit_hash_node(node)
        super
        open_location(node.location, :on_lbrace, '{')
        close_closing_loc(node)
      end

      def heredoc_string_like(node, type)
        if node.opening&.start_with?('<<')
          heredoc_open(node)
          # Heredoc closing contains trailing newline. We need to exclude it
          close_location_start(node.closing_loc) if node.closing_loc && !node.closing.empty?
        elsif node.opening
          open_location(node.location, type, node.opening)
          if node.closing && node.closing != ''
            # Closing of `"#{\n` is "\n". We need to treat it as not-closed.
            close_location_start(node.closing_loc) if node.opening.match?(/\n\z/) || node.closing != "\n"
          end
        end
      end

      def visit_embedded_statements_node(node)
        super
        open_location(node.location, :on_embexpr_beg, '#{')
        close_closing_loc(node)
      end

      def visit_interpolated_string_node(node)
        super
        heredoc_string_like(node, :on_tstring_beg)
      end
      alias visit_string_node visit_interpolated_string_node

      def visit_interpolated_x_string_node(node)
        super
        heredoc_string_like(node, :on_backtick)
      end
      alias visit_x_string_node visit_interpolated_x_string_node

      def visit_symbol_node(node)
        super
        unless node.opening.nil? || node.opening.empty? || node.opening == ':'
          # :"sym" or %s[sym]
          open_location(node.location, :on_symbeg, node.opening)
          close_closing_loc(node)
        end
      end
      alias visit_interpolated_symbol_node visit_symbol_node

      def visit_regular_expression_node(node)
        super
        open_location(node.location, :on_regexp_beg, node.opening)
        close_closing_loc(node)
      end
      alias visit_interpolated_regular_expression_node visit_regular_expression_node

      def visit_parentheses_node(node)
        super
        open_location(node.location, :on_lparen, '(')
        close_closing_loc(node)
      end

      def visit_call_node(node)
        super
        type =
          case node.opening
          when '('
            :on_lparen
          when '['
            :on_lbracket
          end

        if type
          open_location(node.opening_loc, type, node.opening)
          close_closing_loc(node)
        end
      end

      def visit_block_parameters_node(node)
        super
        if node.opening == '('
          open_location(node.location, :on_lparen, '(')
          close_closing_loc(node)
        end
      end

      def visit_lambda_node(node)
        super
        open_location(node.opening_loc, :on_tlambeg, node.opening)
        close_closing_loc(node)
      end

      def visit_super_node(node)
        super
        if node.lparen
          open_location(node.lparen_loc, :on_lparen, '(')
          close_location(node.rparen_loc) if node.rparen == ')'
        end
      end
      alias visit_yield_node visit_super_node
      alias visit_defined_node visit_super_node

      def visit_def_node(node)
        super
        open_location(node.location, :on_kw, 'def')
        if node.lparen == '('
          open_location(node.lparen_loc, :on_lparen, '(')
          close_location(node.rparen_loc) if node.rparen == ')'
        end
        if node.equal
          close_location(node.equal_loc)
        else
          close_end_keyword_loc(node)
        end
      end

      def visit_class_node(node)
        super
        open_location(node.location, :on_kw, 'class')
        close_end_keyword_loc(node)
      end
      alias visit_singleton_class_node visit_class_node

      def visit_module_node(node)
        super
        open_location(node.location, :on_kw, 'module')
        close_end_keyword_loc(node)
      end
    end

    class << self

      # Return a list of open nesting elements at EOF position
      def open_nestings(parse_lex_result)
        parse_by_line(parse_lex_result).last[1]
      end

      # Calculates nesting information [prev_opens, next_opens, min_depth] for each line.
      # Example code
      #   ["hello
      #   world"+(
      # First line
      #   prev_opens: []
      #   next_opens: [lbracket, tstring_beg]
      #   min_depth:  0 (minimum at beginning of line)
      # Second line
      #   prev_opens: [lbracket, tstring_beg]
      #   next_opens: [lbracket, lparen]
      #   min_depth:  1 (minimum just after tstring_end)

      def parse_by_line(parse_lex_result)
        visitor = NestingVisitor.new
        node, tokens = parse_lex_result.value
        node.accept(visitor)
        tokens.each do |token,|
          case token.type
          when :EMBDOC_BEGIN
            visitor.open_location(token.location, :on_embdoc_beg, '=begin')
          when :EMBDOC_END
            visitor.close_location_start(token.location)
          end
        end
        nestings = visitor.nestings
        last_nesting = nestings.last || []

        num_lines = parse_lex_result.source.source.lines.size
        num_lines.times.map do |i|
          prev_opens = i == 0 ? [] : nestings[i - 1] || last_nesting
          opens = nestings[i] || last_nesting
          min_depth = prev_opens.zip(opens).take_while { |s, e| s == e }.size
          [prev_opens, opens, min_depth]
        end
      end
    end
  end
end
