# frozen_string_literal: true

class Pagy
  module I18n
    module P11n
      module Arabic
        module_function

        def plural_for(n = 0)
          mod100 = n % 100

          case
          when n == 0  # rubocop:disable Style/NumericPredicate
            :zero
          when n == 1
            :one
          when n == 2
            :two
          when (3..10).to_a.include?(mod100)
            :few
          when (11..99).to_a.include?(mod100)
            :many
          else
            :other
          end
        end
      end
    end
  end
end
