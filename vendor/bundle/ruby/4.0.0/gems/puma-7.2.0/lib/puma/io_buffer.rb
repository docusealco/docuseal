# frozen_string_literal: true

require 'stringio'

module Puma
  class IOBuffer < StringIO
    def initialize
      super.binmode
    end

    def empty?
      length.zero?
    end

    def reset
      truncate 0
      rewind
    end

    def to_s
      rewind
      read
    end

    # Read & Reset - returns contents and resets
    # @return [String] StringIO contents
    def read_and_reset
      rewind
      str = read
      truncate 0
      rewind
      str
    end

    alias_method :clear, :reset

    # Create an `IoBuffer#append` method that accepts multiple strings and writes them
    if RUBY_ENGINE == 'truffleruby'
      # truffleruby (24.2.1, like ruby 3.3.7)
      #   StringIO.new.write("a", "b") # => `write': wrong number of arguments (given 2, expected 1) (ArgumentError)
      def append(*strs)
        strs.each { |str| write str }
      end
    else
      # Ruby 3+
      #   StringIO.new.write("a", "b") # => 2
      alias_method :append, :write
    end
  end
end
