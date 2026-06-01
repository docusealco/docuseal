# frozen_string_literal: true

class Pagy
  module I18n
    module P11n
      module OneOther
        module_function

        def plural_for(n = 0)
          n == 1 ? :one : :other
        end
      end
    end
  end
end
