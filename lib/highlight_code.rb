# frozen_string_literal: true

module HighlightCode
  module_function

  def call(code, lexer, theme: 'base16.light')
    require 'rouge/themes/base16' unless Rouge::Theme.registry[theme]

    formatter = Rouge::Formatters::HTMLInline.new(theme)
    lexer = Rouge::Lexers.const_get(lexer.to_sym).new
    formatted_code = formatter.format(lexer.lex(code))
    formatted_code = formatted_code.gsub('background-color: #181818', '') if theme == 'base16.dark'
    formatted_code
  end
end
