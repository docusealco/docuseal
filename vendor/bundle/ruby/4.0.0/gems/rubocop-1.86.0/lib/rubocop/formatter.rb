# frozen_string_literal: true

module RuboCop
  # The bootstrap module for formatter.
  module Formatter
    autoload :Colorizable, 'rubocop/formatter/colorizable'
    autoload :TextUtil, 'rubocop/formatter/text_util'

    autoload :BaseFormatter, 'rubocop/formatter/base_formatter'
    autoload :SimpleTextFormatter, 'rubocop/formatter/simple_text_formatter'

    # relies on simple text
    autoload :ClangStyleFormatter, 'rubocop/formatter/clang_style_formatter'
    autoload :DisabledConfigFormatter, 'rubocop/formatter/disabled_config_formatter'
    autoload :EmacsStyleFormatter, 'rubocop/formatter/emacs_style_formatter'
    autoload :FileListFormatter, 'rubocop/formatter/file_list_formatter'
    autoload :FuubarStyleFormatter, 'rubocop/formatter/fuubar_style_formatter'
    autoload :GitHubActionsFormatter, 'rubocop/formatter/github_actions_formatter'
    autoload :HTMLFormatter, 'rubocop/formatter/html_formatter'
    autoload :JSONFormatter, 'rubocop/formatter/json_formatter'
    autoload :JUnitFormatter, 'rubocop/formatter/junit_formatter'
    autoload :MarkdownFormatter, 'rubocop/formatter/markdown_formatter'
    autoload :OffenseCountFormatter, 'rubocop/formatter/offense_count_formatter'
    autoload :PacmanFormatter, 'rubocop/formatter/pacman_formatter'
    autoload :ProgressFormatter, 'rubocop/formatter/progress_formatter'
    autoload :QuietFormatter, 'rubocop/formatter/quiet_formatter'
    autoload :TapFormatter, 'rubocop/formatter/tap_formatter'
    autoload :WorstOffendersFormatter, 'rubocop/formatter/worst_offenders_formatter'

    # relies on progress formatter
    autoload :AutoGenConfigFormatter, 'rubocop/formatter/auto_gen_config_formatter'

    autoload :FormatterSet, 'rubocop/formatter/formatter_set'
  end
end
