# frozen_string_literal: true

module MarkdownToHtml
  LINK_REGEXP = %r{\[([^\]]+)\]\((https?://[^)]+)\)}
  LINK_REPLACE = '<a href="\2">\1</a>'

  module_function

  def call(text)
    text.gsub(LINK_REGEXP, LINK_REPLACE)
  end
end
