# frozen_string_literal: true

module RuboCop
  module LSP
    # Builds LSP text edits for rubocop:disable comments.
    # @api private
    class DisableCommentEdits
      def initialize(offense:, document_encoding:, processed_source:)
        @offense = offense
        @document_encoding = document_encoding
        @processed_source = processed_source
      end

      def edits
        literal_range = multiline_literal_range
        return block_disable_comments(literal_range) if literal_range

        inline_disable_comment
      end

      private

      def inline_disable_comment
        eol = position(@offense.line - 1, @offense.source_line.length, @offense.source_line)
        [text_edit(eol, inline_comment_text)]
      end

      def inline_comment_text
        if @offense.source_line.include?(' # rubocop:disable ')
          ",#{@offense.cop_name}"
        else
          " # rubocop:disable #{@offense.cop_name}"
        end
      end

      def block_disable_comments(range)
        full_line_range = range_by_lines(range)
        leading_whitespace = full_line_range.source_line[/^\s*/].to_s
        [
          disable_edit(full_line_range.first_line, leading_whitespace),
          enable_edit(full_line_range, leading_whitespace)
        ]
      end

      def disable_edit(first_line, leading_whitespace)
        position = position(first_line - 1, 0, '')
        text_edit(position, "#{leading_whitespace}# rubocop:disable #{@offense.cop_name}\n")
      end

      def enable_edit(full_line_range, leading_whitespace)
        last_line = full_line_range.last_line
        last_line_text = full_line_range.source_buffer.source_line(last_line)
        position = position(last_line - 1, last_line_text.length, last_line_text)
        text_edit(position, "\n#{leading_whitespace}# rubocop:enable #{@offense.cop_name}")
      end

      def text_edit(position, new_text)
        range = LanguageServer::Protocol::Interface::Range.new(start: position, end: position)
        LanguageServer::Protocol::Interface::TextEdit.new(range: range, new_text: new_text)
      end

      def position(line, utf8_index, line_text)
        LanguageServer::Protocol::Interface::Position.new(
          line: line,
          character: position_character(utf8_index, line_text)
        )
      end

      def position_character(utf8_index, line_text)
        str = line_text[0, utf8_index]
        if @document_encoding == Encoding::UTF_16LE || @document_encoding.nil?
          str.length + str.b.count("\xf0-\xff".b)
        else
          str.length
        end
      end

      def multiline_literal_range
        return unless @processed_source&.ast

        offense_range = @offense.location
        multiline_ranges&.find do |range|
          eol_comment_would_be_inside_literal?(offense_range, range)
        end
      end

      def multiline_ranges
        @processed_source.ast.each_node.filter_map do |node|
          if surrounding_heredoc?(node)
            heredoc_range(node)
          elsif string_continuation?(node)
            range_by_lines(node.source_range)
          elsif surrounding_percent_array?(node) || multiline_string?(node)
            node.source_range
          end
        end
      end

      def eol_comment_would_be_inside_literal?(offense_range, literal_range)
        offense_line = offense_range.line
        offense_line >= literal_range.first_line && offense_line < literal_range.last_line
      end

      def surrounding_heredoc?(node)
        node.any_str_type? && node.heredoc?
      end

      def heredoc_range(node)
        node.source_range.join(node.loc.heredoc_end)
      end

      def surrounding_percent_array?(node)
        node.array_type? && node.percent_literal?
      end

      def string_continuation?(node)
        node.any_str_type? && node.source.match?(/\\\s*$/)
      end

      def multiline_string?(node)
        node.dstr_type? && node.multiline?
      end

      def range_by_lines(range)
        begin_of_first_line = range.begin_pos - range.column

        last_line = range.source_buffer.source_line(range.last_line)
        last_line_offset = last_line.length - range.last_column
        end_of_last_line = range.end_pos + last_line_offset

        Parser::Source::Range.new(range.source_buffer, begin_of_first_line, end_of_last_line)
      end
    end
  end
end
