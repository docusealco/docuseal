# frozen_string_literal: true

require 'pagy/extras/countless'

Pagy::DEFAULT[:limit] = 10
Pagy::DEFAULT.freeze

ActiveSupport.on_load(:action_view) do
  include Pagy::Frontend
end
