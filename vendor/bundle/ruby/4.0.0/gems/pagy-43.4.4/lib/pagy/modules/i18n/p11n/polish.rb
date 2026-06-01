# frozen_string_literal: true

class Pagy
  module I18n
    module P11n
      module Polish
        module_function

        def plural_for(n = 0)
          mod10  = n % 10
          mod100 = n % 100

          case
          when n == 1
            :one
          when [2, 3, 4].include?(mod10) && ![12, 13, 14].include?(mod100)
            :few
          when [0, 1, 5, 6, 7, 8, 9].include?(mod10) || [12, 13, 14].include?(mod100)
            :many
          else
            :other
          end
        end
      end
    end
  end
end
