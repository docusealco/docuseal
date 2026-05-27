# frozen_string_literal: true

module RuboCop
  # This class wraps the `Parser::Source::Comment` object that represents a
  # special `rubocop:disable` and `rubocop:enable` comment and exposes what
  # cops it contains.
  class DirectiveComment
    # @api private
    LINT_DEPARTMENT = 'Lint'
    # @api private
    LINT_REDUNDANT_DIRECTIVE_COP = "#{LINT_DEPARTMENT}/RedundantCopDisableDirective"
    # @api private
    LINT_SYNTAX_COP = "#{LINT_DEPARTMENT}/Syntax"
    # @api private
    COP_NAME_PATTERN = '([A-Za-z]\w+/)*(?:[A-Za-z]\w+)'
    # @api private
    COP_NAME_PATTERN_NC = '(?:[A-Za-z]\w+/)*[A-Za-z]\w+'
    # @api private
    COP_NAMES_PATTERN_NC = "(?:#{COP_NAME_PATTERN_NC} , )*#{COP_NAME_PATTERN_NC}"
    # @api private
    COP_NAMES_PATTERN = "(?:#{COP_NAME_PATTERN} , )*#{COP_NAME_PATTERN}"
    # @api private
    COPS_PATTERN = "(all|#{COP_NAMES_PATTERN})"
    # @api private
    PUSH_POP_ARGS_PATTERN = "([+\\-]#{COP_NAME_PATTERN_NC}(?:\\s+[+\\-]#{COP_NAME_PATTERN_NC})*)"
    # @api private
    AVAILABLE_MODES = %w[disable enable todo push pop].freeze
    # @api private
    DIRECTIVE_MARKER_PATTERN = '# rubocop : '
    # @api private
    DIRECTIVE_MARKER_REGEXP = Regexp.new(DIRECTIVE_MARKER_PATTERN.gsub(' ', '\s*'))
    # @api private
    DIRECTIVE_HEADER_PATTERN = "#{DIRECTIVE_MARKER_PATTERN}((?:#{AVAILABLE_MODES.join('|')}))\\b"
    # @api private
    DIRECTIVE_COMMENT_REGEXP = Regexp.new(
      "#{DIRECTIVE_HEADER_PATTERN}(?:\\s+#{COPS_PATTERN}|\\s+#{PUSH_POP_ARGS_PATTERN})?"
        .gsub(' ', '\s*')
    )
    # @api private
    TRAILING_COMMENT_MARKER = '--'
    # @api private
    MALFORMED_DIRECTIVE_WITHOUT_COP_NAME_REGEXP = Regexp.new(
      "\\A#{DIRECTIVE_HEADER_PATTERN}\\s*\\z".gsub(' ', '\s*')
    )

    def self.before_comment(line)
      line.split(DIRECTIVE_COMMENT_REGEXP).first
    end

    attr_reader :comment, :cop_registry, :mode, :cops

    def initialize(comment, cop_registry = Cop::Registry.global)
      @comment = comment
      @cop_registry = cop_registry
      match_data = comment.text.match(DIRECTIVE_COMMENT_REGEXP)
      @match_data = match_data&.pre_match&.match?(/\A#\s*\z/) ? nil : match_data
      @mode, @cops = match_captures
    end

    # Checks if the comment starts with `# rubocop:` marker
    def start_with_marker?
      comment.text.start_with?(DIRECTIVE_MARKER_REGEXP)
    end

    # Checks if the comment is malformed as a `# rubocop:` directive
    def malformed?
      return true if !start_with_marker? || @match_data.nil?
      return true if missing_cop_name?

      tail = @match_data.post_match.lstrip
      !(tail.empty? || tail.start_with?(TRAILING_COMMENT_MARKER))
    end

    # Checks if the directive comment is missing a cop name
    def missing_cop_name?
      return false if push? || pop?

      MALFORMED_DIRECTIVE_WITHOUT_COP_NAME_REGEXP.match?(comment.text)
    end

    # Checks if this directive relates to single line
    def single_line?
      !comment.text.start_with?(DIRECTIVE_COMMENT_REGEXP)
    end

    # Checks if this directive contains all the given cop names
    def match?(cop_names)
      parsed_cop_names.uniq.sort == cop_names.uniq.sort
    end

    def range
      match = comment.text.match(DIRECTIVE_COMMENT_REGEXP)
      begin_pos = comment.source_range.begin_pos
      Parser::Source::Range.new(
        comment.source_range.source_buffer, begin_pos + match.begin(0), begin_pos + match.end(0)
      )
    end

    # Returns match captures to directive comment pattern
    def match_captures
      @match_captures ||= @match_data && begin
        captures = @match_data.captures
        mode = captures[0]
        # COPS_PATTERN is at captures[1], PUSH_POP_ARGS_PATTERN is at captures[4]
        cops = captures[1] || captures[4]
        [mode, cops]
      end
    end

    # Checks if this directive disables cops
    def disabled?
      %w[disable todo].include?(mode)
    end

    # Checks if this directive enables cops
    def enabled?
      mode == 'enable'
    end

    # Checks if this directive is a push
    def push?
      mode == 'push'
    end

    # Checks if this directive is a pop
    def pop?
      mode == 'pop'
    end

    # Returns the push arguments as a hash of cop names with their operations
    def push_args
      @push_args ||= parse_push_args
    end

    # Checks if this directive enables all cops
    def enabled_all?
      !disabled? && all_cops?
    end

    # Checks if this directive disables all cops
    def disabled_all?
      disabled? && all_cops?
    end

    # Checks if all cops specified in this directive
    def all_cops?
      cops == 'all'
    end

    # Returns array of specified in this directive cop names
    def cop_names
      @cop_names ||= all_cops? ? all_cop_names : parsed_cop_names
    end

    # Returns an array of cops for this directive comment, without resolving departments
    def raw_cop_names
      @raw_cop_names ||= (cops || '').split(/,\s*/)
    end

    # Returns array of specified in this directive department names
    # when all department disabled
    def department_names
      raw_cop_names.select { |cop| department?(cop) }
    end

    # Checks if directive departments include cop
    def in_directive_department?(cop)
      department_names.any? { |department| cop.start_with?(department) }
    end

    # Checks if cop department has already used in directive comment
    def overridden_by_department?(cop)
      in_directive_department?(cop) && raw_cop_names.include?(cop)
    end

    def directive_count
      raw_cop_names.count
    end

    # Returns line number for directive
    def line_number
      comment.source_range.line
    end

    private

    def parsed_cop_names
      cops = raw_cop_names.map do |name|
        department?(name) ? cop_names_for_department(name) : name
      end.flatten
      cops - [LINT_SYNTAX_COP]
    end

    def department?(name)
      cop_registry.department?(name)
    end

    def all_cop_names
      exclude_lint_department_cops(cop_registry.names)
    end

    def cop_names_for_department(department)
      names = cop_registry.names_for_department(department)
      department == LINT_DEPARTMENT ? exclude_lint_department_cops(names) : names
    end

    def exclude_lint_department_cops(cops)
      cops - [LINT_REDUNDANT_DIRECTIVE_COP, LINT_SYNTAX_COP]
    end

    def parse_push_args
      return {} unless push? && cops

      args = {}
      cops.split.each do |cop_spec|
        op = cop_spec[0]
        cop_name = cop_spec[1..]
        args[op] ||= []
        args[op] << cop_name
      end
      args
    end
  end
end
