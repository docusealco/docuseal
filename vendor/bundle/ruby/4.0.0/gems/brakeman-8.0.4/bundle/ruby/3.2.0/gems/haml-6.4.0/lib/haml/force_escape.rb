# frozen_string_literal: true
require 'haml/escape'

module Haml
  # This module allows Temple::Filter to dispatch :fescape on `#compile`.
  module FescapeDispathcer
    def on_fescape(flag, exp)
      [:fescape, flag, compile(exp)]
    end
  end
  ::Temple::Filter.include FescapeDispathcer

  # Unlike Haml::Escape, this escapes value even if it's html_safe.
  class ForceEscape < Escape
    def initialize(opts = {})
      super
      @escape_code = options[:escape_code] || "::Haml::Util.escape_html((%s))"
      @escaper = eval("proc {|v| #{@escape_code % 'v'} }")
    end

    alias_method :on_fescape, :on_escape

    # ForceEscape doesn't touch :escape expression.
    # This method is not used if it's inserted after Haml::Escape.
    def on_escape(flag, exp)
      [:escape, flag, compile(exp)]
    end
  end
end
