# frozen_string_literal: true
module Slim
  # Tilt template implementation for Slim
  # @api public
  Template = Temple::Templates::Tilt(Slim::Engine, register_as: :slim)
end
