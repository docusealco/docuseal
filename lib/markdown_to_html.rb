# frozen_string_literal: true

module MarkdownToHtml
  LINK_REGEXP = %r{\[([^\]]+)\]\((https?://[^)]+)\)}

  module_function

  def call(text)
    text.gsub(LINK_REGEXP) do
      ApplicationController.helpers.link_to(Regexp.last_match(1), Regexp.last_match(2))
    end
  end
end
