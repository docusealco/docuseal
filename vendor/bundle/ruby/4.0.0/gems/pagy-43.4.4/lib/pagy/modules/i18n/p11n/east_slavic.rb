# frozen_string_literal: true

class Pagy
  module I18n
    module P11n
      module EastSlavic
        module_function

        def plural_for(n = 0)
          mod10  = n % 10
          mod100 = n % 100

          case
          when mod10 == 1 && mod100 != 11
            :one
          when (2..4).to_a.include?(mod10) && !(12..14).to_a.include?(mod100)
            :few
          when mod10 == 0 || (5..9).to_a.include?(mod10) || (11..14).to_a.include?(mod100) # rubocop:disable Style/NumericPredicate
            :many
          else
            :other
          end
        end
      end
    end
  end
end
