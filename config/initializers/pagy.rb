# frozen_string_literal: true

Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT.freeze

ActiveSupport.on_load(:action_view) do
  include Pagy::Frontend
end
