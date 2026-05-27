# frozen_string_literal: true
require 'haml/util'

module Haml
  class Escape < Temple::Filters::Escapable
    def initialize(opts = {})
      super
      @escape_code = options[:escape_code] ||
        "::Haml::Util.escape_html#{options[:use_html_safe] ? '_safe' : ''}((%s))"
      @escaper = eval("proc {|v| #{@escape_code % 'v'} }")
    end
  end
end
