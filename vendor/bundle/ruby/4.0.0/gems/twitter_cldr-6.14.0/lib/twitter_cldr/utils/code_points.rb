# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Utils
    module CodePoints

      class << self

        def to_char(code_point)
          [code_point].pack('U*')
        end

        def from_char(char)
          char.unpack('U*').first
        end

        def from_chars(chars)
          chars.map { |char| from_char(char) }
        end

        def to_chars(code_points)
          code_points.map { |code_point| to_char(code_point) }
        end

        def from_string(str)
          str.unpack("U*")
        end

        def to_string(code_points)
          code_points.map { |code_point| to_char(code_point) }.join
        end

      end

    end
  end
end