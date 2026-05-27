# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    module Numbers
      class Base
        def interpolate(string, value, orientation = :right)
          value  = value.to_s
          length = value.length
          start  = orientation == :left ? 0 : -length

          string = string.dup
          string = string.ljust(length, '#') if string.length < length
          string[start, length] = value
          string.gsub('#', '')
        end
      end
    end
  end
end