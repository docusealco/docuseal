# frozen_string_literal: true

module Zip
  module FileSystem
    class DirectoryIterator # :nodoc:all
      include Enumerable

      def initialize(filenames)
        @filenames = filenames
        @index = 0
      end

      def close
        @filenames = nil
      end

      def each(&a_proc)
        raise IOError, 'closed directory' if @filenames.nil?

        @filenames.each(&a_proc)
      end

      def read
        raise IOError, 'closed directory' if @filenames.nil?

        @filenames[(@index += 1) - 1]
      end

      def rewind
        raise IOError, 'closed directory' if @filenames.nil?

        @index = 0
      end

      def seek(position)
        raise IOError, 'closed directory' if @filenames.nil?

        @index = position
      end

      def tell
        raise IOError, 'closed directory' if @filenames.nil?

        @index
      end
    end
  end
end
