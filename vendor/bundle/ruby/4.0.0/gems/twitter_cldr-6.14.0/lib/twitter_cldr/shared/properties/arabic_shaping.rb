# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    module Properties
      module ArabicShaping

        JOINING_TYPES = {
          'R' => 'Right_Joining',
          'L' => 'Left_Joining',
          'D' => 'Dual_Joining',
          'C' => 'Join_Causing',
          'U' => 'Non_Joining',
          'T' => 'Transparent'
        }

        class << self

          def joining_type_for_general_category(general_category)
            case general_category
              when 'Mn', 'Me', 'Cf'
                joining_types['T']
              else
                joining_types['U']
            end
          end

          def joining_types
            JOINING_TYPES
          end

        end

      end
    end
  end
end
