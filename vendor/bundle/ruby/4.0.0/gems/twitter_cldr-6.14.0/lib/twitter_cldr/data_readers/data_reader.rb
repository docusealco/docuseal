# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module DataReaders
    class DataReader

      attr_reader :locale

      def initialize(locale)
        @locale = TwitterCldr.convert_locale(locale)
      end

      def pattern_at_path(path)
        traverse(path)
      end

      private

      def traverse(path, hash = resource, &block)
        TwitterCldr::Utils.traverse_hash(hash, path, &block)
      end

      def resource
        raise NotImplementedError
      end

    end
  end
end
