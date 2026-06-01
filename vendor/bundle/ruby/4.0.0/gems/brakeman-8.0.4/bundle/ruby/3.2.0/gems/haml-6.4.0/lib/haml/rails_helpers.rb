# frozen_string_literal: false
require 'haml/helpers'

# There are only helpers that depend on ActionView internals.
module Haml
  module RailsHelpers
    include Helpers
    extend self

    DEFAULT_PRESERVE_TAGS = %w[textarea pre code].freeze

    def find_and_preserve(input = nil, tags = DEFAULT_PRESERVE_TAGS, &block)
      return find_and_preserve(capture_haml(&block), input || tags) if block

      tags = tags.each_with_object('') do |t, s|
        s << '|' unless s.empty?
        s << Regexp.escape(t)
      end

      re = /<(#{tags})([^>]*)>(.*?)(<\/\1>)/im
      input.to_s.gsub(re) do |s|
        s =~ re # Can't rely on $1, etc. existing since Rails' SafeBuffer#gsub is incompatible
        "<#{$1}#{$2}>#{preserve($3)}</#{$1}>"
      end
    end

    def preserve(input = nil, &block)
      return preserve(capture_haml(&block)) if block
      super.html_safe
    end

    def surround(front, back = front, &block)
      output = capture_haml(&block)
      front  = escape_once(front) unless front.html_safe?
      back   = escape_once(back)  unless back.html_safe?
      "#{front}#{output.chomp}#{back}\n".html_safe
    end

    def precede(str, &block)
      str = escape_once(str) unless str.html_safe?
      "#{str}#{capture_haml(&block).chomp}\n".html_safe
    end

    def succeed(str, &block)
      str = escape_once(str) unless str.html_safe?
      "#{capture_haml(&block).chomp}#{str}\n".html_safe
    end

    def capture_haml(*args, &block)
      capture(*args, &block)
    end
  end
end
