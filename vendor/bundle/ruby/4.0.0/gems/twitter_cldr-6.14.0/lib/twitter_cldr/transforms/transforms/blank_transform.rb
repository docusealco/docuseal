# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Transforms

      class BlankTransform < TransformRule
        TRANSFORM = 'blank'.freeze

        def self.instance
          @instance ||= new
        end

        private

        def initialize
          super(nil, nil)
        end

        public

        def apply_to(cursor)
          puts 'BLANK' if $debug
        end

        def null?
          false
        end

        def blank?
          true
        end

        def transform
          TRANSFORM
        end

        def has_transform?(*args)
          false
        end

        def apply_to(cursor)
          # do nothing
        end
      end

    end
  end
end
