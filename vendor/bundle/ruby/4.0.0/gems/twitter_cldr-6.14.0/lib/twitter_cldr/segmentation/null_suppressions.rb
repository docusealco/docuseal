# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Segmentation
    class NullSuppressions
      include Singleton

      def should_break?(_cursor)
        true
      end
    end
  end
end
