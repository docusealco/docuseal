# frozen_string_literal: true

module RuboCop
  # This class parses the special `rubocop:disable` comments in a source
  # and provides a way to check if each cop is enabled at arbitrary line.
  class CommentConfig
    extend SimpleForwardable

    CONFIG_DISABLED_LINE_RANGE_MIN = -Float::INFINITY

    # This class provides an API compatible with RuboCop::DirectiveComment
    # to be used for cops that are disabled in the config file
    class ConfigDisabledCopDirectiveComment
      include RuboCop::Ext::Comment

      attr_reader :text, :loc, :line_number

      Loc = Struct.new(:expression)
      Expression = Struct.new(:line)

      def initialize(cop_name)
        @text = "# rubocop:disable #{cop_name}"
        @line_number = CONFIG_DISABLED_LINE_RANGE_MIN
        @loc = Loc.new(Expression.new(CONFIG_DISABLED_LINE_RANGE_MIN))
      end
    end

    CopAnalysis = Struct.new(:line_ranges, :start_line_number)

    attr_reader :processed_source

    def_delegators :@processed_source, :config, :registry

    def initialize(processed_source)
      @processed_source = processed_source
      @no_directives = !processed_source.raw_source.include?('rubocop')
      @stack = []
    end

    def cop_enabled_at_line?(cop, line_number)
      cop = cop.cop_name if cop.respond_to?(:cop_name)
      disabled_line_ranges = cop_disabled_line_ranges[cop]
      return true unless disabled_line_ranges

      disabled_line_ranges.none? { |range| range.include?(line_number) }
    end

    def cop_opted_in?(cop)
      opt_in_cops.include?(cop.cop_name)
    end

    def cop_disabled_line_ranges
      @cop_disabled_line_ranges ||= analyze
    end

    def extra_enabled_comments
      disable_count = Hash.new(0)
      registry.disabled(config).each do |cop|
        disable_count[cop.cop_name] += 1
      end
      extra_enabled_comments_with_names(extras: Hash.new { |h, k| h[k] = [] }, names: disable_count)
    end

    def comment_only_line?(line_number)
      non_comment_token_line_numbers.none?(line_number)
    end

    private

    def extra_enabled_comments_with_names(extras:, names:)
      each_directive do |directive|
        next unless comment_only_line?(directive.line_number)
        next if directive.push? || directive.pop?

        if directive.enabled_all?
          handle_enable_all(directive, names, extras)
        else
          handle_switch(directive, names, extras)
        end
      end

      extras
    end

    def opt_in_cops
      @opt_in_cops ||= begin
        cops = Set.new
        each_directive do |directive|
          next unless directive.enabled?
          next if directive.all_cops?

          cops.merge(directive.raw_cop_names)
        end
        cops
      end
    end

    def analyze # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      return {} if @no_directives

      analyses = Hash.new { |hash, key| hash[key] = CopAnalysis.new([], nil) }
      inject_disabled_cops_directives(analyses)

      each_directive do |directive|
        if directive.push?
          resolved = resolve_push_cops(directive)
          @stack.push(snapshot_cops(analyses, resolved.values.flatten))
          apply_push(analyses, resolved, directive.line_number)
        elsif directive.pop?
          pop_state(analyses, directive.line_number) if @stack.any?
        else
          directive.cop_names.each do |cop_name|
            cop_name = qualified_cop_name(cop_name)
            analyses[cop_name] = analyze_cop(analyses[cop_name], directive)
          end
        end
      end

      analyses.each_with_object({}) do |element, hash|
        cop_name, analysis = *element
        hash[cop_name] = cop_line_ranges(analysis)
      end
    end

    def snapshot_cops(analyses, cop_names)
      cop_names.to_h { |name| [name, analyses[name].dup] }
    end

    def resolve_push_cops(directive)
      directive.push_args.transform_values do |names|
        names.flat_map { |name| expand_cop_name(name) }
      end
    end

    def expand_cop_name(name)
      registry = Cop::Registry.global
      cops = registry.department?(name) ? registry.names_for_department(name) : [name]
      cops.map { |c| qualified_cop_name(c) }
    end

    def apply_push(analyses, resolved_cops, line)
      resolved_cops.each do |op, cops|
        cops.each { |cop| apply_cop_op(analyses, op, cop, line) }
      end
    end

    def apply_cop_op(analyses, operation, cop, line)
      analysis = analyses[cop]
      if operation == '-' && !analysis.start_line_number
        analyses[cop] = CopAnalysis.new(analysis.line_ranges, line)
      elsif operation == '+' && analysis.start_line_number
        analyses[cop] =
          CopAnalysis.new(analysis.line_ranges + [analysis.start_line_number..line], nil)
      end
    end

    def pop_state(analyses, line)
      saved = @stack.pop
      saved.each do |cop, old|
        cur = analyses[cop]
        new_range = cur.start_line_number ? [cur.start_line_number..(line - 1)] : []
        ranges = cur.line_ranges + new_range
        new_start = old.start_line_number ? line : nil
        analyses[cop] = CopAnalysis.new(ranges, new_start)
      end
    end

    def inject_disabled_cops_directives(analyses)
      registry.disabled(config).each do |cop|
        analyses[cop.cop_name] = analyze_cop(
          analyses[cop.cop_name],
          DirectiveComment.new(ConfigDisabledCopDirectiveComment.new(cop.cop_name))
        )
      end
    end

    def analyze_cop(analysis, directive)
      # Disabling cops after comments like `#=SomeDslDirective` does not related to single line
      if !comment_only_line?(directive.line_number) || directive.single_line?
        analyze_single_line(analysis, directive)
      elsif directive.disabled?
        analyze_disabled(analysis, directive)
      else
        analyze_rest(analysis, directive)
      end
    end

    def analyze_single_line(analysis, directive)
      return analysis unless directive.disabled?

      line = directive.line_number
      CopAnalysis.new(analysis.line_ranges + [(line..line)], analysis.start_line_number)
    end

    def analyze_disabled(analysis, directive)
      line = directive.line_number
      start_line = analysis.start_line_number
      new_ranges = start_line ? analysis.line_ranges + [start_line..line] : analysis.line_ranges
      CopAnalysis.new(new_ranges, line)
    end

    def analyze_rest(analysis, directive)
      line = directive.line_number
      start_line = analysis.start_line_number
      new_ranges = start_line ? analysis.line_ranges + [start_line..line] : analysis.line_ranges
      CopAnalysis.new(new_ranges, nil)
    end

    def cop_line_ranges(analysis)
      return analysis.line_ranges unless analysis.start_line_number

      analysis.line_ranges + [(analysis.start_line_number..Float::INFINITY)]
    end

    def each_directive
      return if @no_directives

      processed_source.comments.each do |comment|
        directive = DirectiveComment.new(comment)
        yield directive if directive.cop_names
      end
    end

    def qualified_cop_name(cop_name)
      Cop::Registry.qualified_cop_name(cop_name.strip, processed_source.file_path)
    end

    def non_comment_token_line_numbers
      @non_comment_token_line_numbers ||= begin
        non_comment_tokens = processed_source.tokens.reject(&:comment?)
        non_comment_tokens.map(&:line).uniq
      end
    end

    def handle_enable_all(directive, names, extras)
      enabled_cops = 0
      names.each do |name, counter|
        next unless counter.positive?

        names[name] -= 1
        enabled_cops += 1
      end

      extras[directive.comment] << 'all' if enabled_cops.zero?
    end

    # Collect cops that have been disabled or enabled by name in a directive comment
    # so that `Lint/RedundantCopEnableDirective` can register offenses correctly.
    def handle_switch(directive, names, extras)
      directive.cop_names.each do |name|
        if directive.disabled?
          names[name] += 1
        elsif names[name].positive?
          names[name] -= 1
        else
          extras[directive.comment] << name
        end
      end
    end
  end
end
