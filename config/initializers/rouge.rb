# frozen_string_literal: true

module Rouge
  autoload :InheritableHash, 'rouge/util'
  autoload :Token, 'rouge/token'
  autoload :Lexer, 'rouge/lexer'
  autoload :RegexLexer, 'rouge/regex_lexer'

  module Lexers
    autoload :JSON, 'rouge/lexers/json'
    autoload :Shell, 'rouge/lexers/shell'
  end

  autoload :Formatter, 'rouge/formatter'

  module Formatters
    autoload :HTML, 'rouge/formatters/html'
    autoload :HTMLInline, 'rouge/formatters/html_inline'
  end

  autoload :Theme, 'rouge/theme'
end
