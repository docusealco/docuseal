# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for indentation that doesn't use the specified number of spaces.
      # The indentation width can be configured using the `Width` setting. The default width is 2.
      # The block body indentation for method chain blocks can be configured using the
      # `EnforcedStyleAlignWith` setting.
      #
      # See also the `Layout/IndentationConsistency` cop which is the companion to this one.
      #
      # @example Width: 2 (default)
      #   # bad
      #   class A
      #    def test
      #     puts 'hello'
      #    end
      #   end
      #
      #   # good
      #   class A
      #     def test
      #       puts 'hello'
      #     end
      #   end
      #
      # @example AllowedPatterns: ['^\s*module']
      #   # bad
      #   module A
      #   class B
      #     def test
      #     puts 'hello'
      #     end
      #   end
      #   end
      #
      #   # good
      #   module A
      #   class B
      #     def test
      #       puts 'hello'
      #     end
      #   end
      #   end
      #
      # @example EnforcedStyleAlignWith: start_of_line (default)
      #   # good
      #   records.uniq { |el| el[:profile_id] }
      #          .map do |message|
      #     SomeJob.perform_later(message[:id])
      #   end
      #
      # @example EnforcedStyleAlignWith: relative_to_receiver
      #   # good
      #   records.uniq { |el| el[:profile_id] }
      #          .map do |message|
      #            SomeJob.perform_later(message[:id])
      #          end
      class IndentationWidth < Base # rubocop:disable Metrics/ClassLength
        include ConfigurableEnforcedStyle
        include EndKeywordAlignment
        include Alignment
        include CheckAssignment
        include AllowedPattern
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use %<configured_indentation_width>d (not %<indentation>d) ' \
              '%<indentation_type>s for%<name>s indentation.'

        # @!method access_modifier?(node)
        def_node_matcher :access_modifier?, <<~PATTERN
          [(send ...) access_modifier?]
        PATTERN

        def on_rescue(node)
          check_indentation(node.loc.else, node.else_branch)
        end

        def on_resbody(node)
          check_indentation(node.loc.keyword, node.body)
        end
        alias on_for on_resbody

        def on_ensure(node)
          check_indentation(node.loc.keyword, node.branch)
        end

        def on_kwbegin(node)
          # Check indentation against end keyword but only if it's first on its
          # line.
          return unless begins_its_line?(node.loc.end)

          check_indentation(node.loc.end, node.children.first)
        end

        def on_block(node)
          end_loc = node.loc.end

          return unless begins_its_line?(end_loc)

          base_loc = block_body_indentation_base(node, end_loc)
          check_indentation(base_loc, node.body)

          return unless indented_internal_methods_style?
          return unless contains_access_modifier?(node.body)

          check_members(end_loc, [node.body])
        end

        alias on_numblock on_block
        alias on_itblock on_block

        def on_class(node)
          base = node.loc.keyword
          return if same_line?(base, node.body)

          check_members(base, [node.body])
        end
        alias on_sclass on_class
        alias on_module on_class

        def on_send(node)
          super
          return unless node.adjacent_def_modifier?

          def_end_config = config.for_cop('Layout/DefEndAlignment')
          style = def_end_config['EnforcedStyleAlignWith'] || 'start_of_line'
          base = if style == 'def'
                   node.first_argument
                 else
                   leftmost_modifier_of(node) || node
                 end

          check_indentation(base.source_range, node.first_argument.body)
          ignore_node(node.first_argument)
        end
        alias on_csend on_send

        def on_def(node)
          return if ignored_node?(node)

          check_indentation(node.loc.keyword, node.body)
        end
        alias on_defs on_def

        def on_while(node, base = node)
          return if ignored_node?(node)

          return unless node.single_line_condition?

          check_indentation(base.loc, node.body)
        end

        alias on_until on_while

        def on_case(case_node)
          case_node.when_branches.each do |when_node|
            check_indentation(when_node.loc.keyword, when_node.body)
          end

          check_indentation(case_node.when_branches.last.loc.keyword, case_node.else_branch)
        end

        def on_case_match(case_match)
          case_match.in_pattern_branches.each do |in_pattern_node|
            check_indentation(in_pattern_node.loc.keyword, in_pattern_node.body)
          end

          else_branch = case_match.else_branch&.empty_else_type? ? nil : case_match.else_branch

          check_indentation(case_match.in_pattern_branches.last.loc.keyword, else_branch)
        end

        def on_if(node, base = node)
          return if ignored_node?(node)
          return if node.ternary? || node.modifier_form?

          check_if(node, node.body, node.else_branch, base.loc)
        end

        private

        def autocorrect(corrector, node)
          return unless node

          AlignmentCorrector.correct(corrector, processed_source, node, @column_delta)
        end

        def check_members(base, members)
          check_indentation(base, select_check_member(members.first))

          return unless members.any? && members.first.begin_type?

          if indented_internal_methods_style?
            check_members_for_indented_internal_methods_style(members)
          else
            check_members_for_normal_style(base, members)
          end
        end

        def select_check_member(member)
          return unless member

          if access_modifier?(member.children.first)
            return if access_modifier_indentation_style == 'outdent'

            member.children.first
          else
            member
          end
        end

        def check_members_for_indented_internal_methods_style(members)
          each_member(members) do |member, previous_modifier|
            check_indentation(previous_modifier, member, indentation_consistency_style)
          end
        end

        def check_members_for_normal_style(base, members)
          members.first.children.each do |member|
            next if member.send_type? && member.access_modifier?

            check_indentation(base, member)
          end
        end

        def each_member(members)
          previous_modifier = nil
          members.first.children.each do |member|
            if member.send_type? && member.special_modifier?
              previous_modifier = member
            elsif previous_modifier
              yield member, previous_modifier.source_range
              previous_modifier = nil
            end
          end
        end

        def indented_internal_methods_style?
          indentation_consistency_style == 'indented_internal_methods'
        end

        def special_modifier?(node)
          node.bare_access_modifier? && SPECIAL_MODIFIERS.include?(node.source)
        end

        def access_modifier_indentation_style
          config.for_cop('Layout/AccessModifierIndentation')['EnforcedStyle']
        end

        def indentation_consistency_style
          config.for_cop('Layout/IndentationConsistency')['EnforcedStyle']
        end

        def check_assignment(node, rhs)
          # If there are method calls chained to the right hand side of the
          # assignment, we let rhs be the receiver of those method calls before
          # we check its indentation.
          rhs = first_part_of_call_chain(rhs)
          return unless rhs

          end_config = config.for_cop('Layout/EndAlignment')
          style = end_config['EnforcedStyleAlignWith'] || 'keyword'
          base = variable_alignment?(node.loc, rhs, style.to_sym) ? node : rhs

          case rhs.type
          when :if            then on_if(rhs, base)
          when :while, :until then on_while(rhs, base)
          else                     return
          end

          ignore_node(rhs)
        end

        def check_if(node, body, else_clause, base_loc)
          return if node.ternary?

          check_indentation(base_loc, body)
          return unless else_clause

          # If the else clause is an elsif, it will get its own on_if call so
          # we don't need to process it here.
          return if else_clause.if_type? && else_clause.elsif?

          check_indentation(node.loc.else, else_clause)
        end

        def check_indentation(base_loc, body_node, style = 'normal')
          return unless indentation_to_check?(base_loc, body_node)

          indentation = column_offset_between(body_node.loc, base_loc)
          @column_delta = configured_indentation_width - indentation
          return if @column_delta.zero?

          offense(body_node, indentation, style)
        end

        def offense(body_node, indentation, style)
          # This cop only autocorrects the first statement in a def body, for
          # example.
          body_node = body_node.children.first if body_node.begin_type? && !parentheses?(body_node)

          # Since autocorrect changes a number of lines, and not only the line
          # where the reported offending range is, we avoid autocorrection if
          # this cop has already found other offenses is the same
          # range. Otherwise, two corrections can interfere with each other,
          # resulting in corrupted code.
          node = if autocorrect? && other_offense_in_same_range?(body_node)
                   nil
                 else
                   body_node
                 end

          name = style == 'normal' ? '' : " #{style}"
          message = message(configured_indentation_width, indentation, name)

          add_offense(offending_range(body_node, indentation), message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def message(configured_indentation_width, indentation, name)
          if using_tabs?
            message_for_tabs(configured_indentation_width, indentation, name)
          else
            message_for_spaces(configured_indentation_width, indentation, name)
          end
        end

        def message_for_tabs(configured_indentation_width, indentation, name)
          configured_tabs = 1
          actual_tabs = indentation / configured_indentation_width

          format(
            MSG,
            configured_indentation_width: configured_tabs,
            indentation: actual_tabs,
            indentation_type: 'tabs',
            name: name
          )
        end

        def message_for_spaces(configured_indentation_width, indentation, name)
          format(
            MSG,
            configured_indentation_width: configured_indentation_width,
            indentation: indentation,
            indentation_type: 'spaces',
            name: name
          )
        end

        # Returns true if the given node is within another node that has
        # already been marked for autocorrection by this cop.
        def other_offense_in_same_range?(node)
          expr = node.source_range
          @offense_ranges ||= []

          return true if @offense_ranges.any? { |r| within?(expr, r) }

          @offense_ranges << expr
          false
        end

        def indentation_to_check?(base_loc, body_node)
          return false if skip_check?(base_loc, body_node)

          if body_node.rescue_type?
            check_rescue?(body_node)
          elsif body_node.ensure_type?
            block_body, = *body_node # rubocop:disable InternalAffairs/NodeDestructuring
            if block_body&.rescue_type?
              check_rescue?(block_body)
            else
              !block_body.nil?
            end
          else
            true
          end
        end

        def check_rescue?(rescue_node)
          rescue_node.body
        end

        def skip_check?(base_loc, body_node)
          return true if allowed_line?(base_loc)
          return true unless body_node

          # Don't check if expression is on same line as "then" keyword, etc.
          return true if same_line?(body_node, base_loc)

          return true if starts_with_access_modifier?(body_node)

          # Don't check indentation if the line doesn't start with the body.
          # For example, lines like "else do_something".
          first_char_pos_on_line = body_node.source_range.source_line =~ /\S/
          body_node.loc.column != first_char_pos_on_line
        end

        def offending_range(body_node, indentation)
          expr = body_node.source_range
          begin_pos = expr.begin_pos

          ind = if using_tabs?
                  begin_pos - line_indentation(expr).length
                else
                  begin_pos - indentation
                end

          pos = indentation >= 0 ? ind..begin_pos : begin_pos..ind
          range_between(pos.begin, pos.end)
        end

        def starts_with_access_modifier?(body_node)
          return false unless body_node.begin_type?

          starting_node = body_node.children.first
          return false unless starting_node

          starting_node.send_type? && starting_node.bare_access_modifier?
        end

        def contains_access_modifier?(body_node)
          return false unless body_node&.begin_type?

          body_node.children.any? { |child| child.send_type? && child.bare_access_modifier? }
        end

        def indentation_style
          config.for_cop('Layout/IndentationStyle')['EnforcedStyle'] || 'spaces'
        end

        def using_tabs?
          indentation_style == 'tabs'
        end

        def column_offset_between(base_range, range)
          return super unless using_tabs?

          base_uses_tabs = line_uses_tabs?(base_range)
          range_uses_tabs = line_uses_tabs?(range)

          return super unless base_uses_tabs || range_uses_tabs

          visual_column(base_range) - visual_column(range)
        end

        def line_indentation(range)
          line = processed_source.lines[range.line - 1]
          line[0...range.column]
        end

        def line_uses_tabs?(range)
          line_indentation(range).include?("\t")
        end

        def visual_column(range)
          indentation = line_indentation(range)

          tab_count = indentation.count("\t")
          space_count = indentation.count(' ')

          (tab_count * configured_indentation_width) + space_count
        end

        def leftmost_modifier_of(node)
          return node unless node.parent&.send_type?

          leftmost_modifier_of(node.parent)
        end

        def block_body_indentation_base(node, end_loc)
          if style == :relative_to_receiver && dot_on_new_line?(node)
            node.send_node.loc.dot
          else
            end_loc
          end
        end

        def dot_on_new_line?(node)
          send_node = node.send_node
          return false unless send_node.loc?(:dot)

          receiver = send_node.receiver
          receiver && receiver.last_line < send_node.loc.dot.line
        end
      end
    end
  end
end
