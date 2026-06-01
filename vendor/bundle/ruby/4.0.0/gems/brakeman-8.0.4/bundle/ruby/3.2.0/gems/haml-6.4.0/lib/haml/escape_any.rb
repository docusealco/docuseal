# frozen_string_literal: true
require 'haml/escape'

module Haml
  # This module allows Temple::Filter to dispatch :fescape on `#compile`.
  module EscapeanyDispathcer
    def on_escapeany(flag, exp)
      [:escapeany, flag, compile(exp)]
    end
  end
  ::Temple::Filter.include EscapeanyDispathcer

  # Unlike Haml::Escape, this calls to_s when not escaped.
  class EscapeAny < Escape
    alias_method :on_escapeany, :on_escape

    def on_dynamic(value)
      [:dynamic, @escape ? @escape_code % value : "(#{value}).to_s"]
    end
  end
end
