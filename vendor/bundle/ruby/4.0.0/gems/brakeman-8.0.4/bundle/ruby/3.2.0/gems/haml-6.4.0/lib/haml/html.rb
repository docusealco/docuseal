# frozen_string_literal: true
module Haml
  class HTML < Temple::HTML::Fast
    DEPRECATED_FORMATS = %i[html4 html5].freeze

    def initialize(opts = {})
      if DEPRECATED_FORMATS.include?(opts[:format])
        opts = opts.dup
        opts[:format] = :html
      end
      super(opts)
    end

    # This dispatcher supports Haml's "revealed" conditional comment.
    def on_html_condcomment(condition, content, revealed = false)
      on_html_comment [:multi,
                       [:static, "[#{condition}]>#{'<!-->' if revealed}"],
                       content,
                       [:static, "#{'<!--' if revealed}<![endif]"]]
    end
  end
end
