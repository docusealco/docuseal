# frozen_string_literal: true

class Pagy
  module I18n
    module P11n
      module OneUptoTwoOther
        module_function

        def plural_for(n = 0)
          n >= 0 && n < 2 ? :one : :other
        end
      end
    end
  end
end
