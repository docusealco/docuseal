# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Filters

      class NullFilter < FilterRule
        def matches?(cursor)
          true
        end

        def forward?
          true
        end

        def backward?
          true
        end
      end

    end
  end
end
