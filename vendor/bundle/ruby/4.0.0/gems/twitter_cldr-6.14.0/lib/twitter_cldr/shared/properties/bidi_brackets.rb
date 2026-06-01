# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    module Properties
      module BidiBrackets

        BRACKET_TYPES = {
          'O' => 'Open',
          'C' => 'Close',
          'N' => 'None'
        }

        class << self

          def bracket_types
            BRACKET_TYPES
          end

        end

      end
    end
  end
end
