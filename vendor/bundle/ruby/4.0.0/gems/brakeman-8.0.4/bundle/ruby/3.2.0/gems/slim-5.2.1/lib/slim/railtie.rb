# frozen_string_literal: true

module Slim
  class Railtie < ::Rails::Railtie
    initializer 'initialize slim template handler' do
      ActiveSupport.on_load(:action_view) do
        Slim::RailsTemplate = Temple::Templates::Rails(Slim::Engine,
                                                       register_as: :slim,
                                                       # Use rails-specific generator. This is necessary
                                                       # to support block capturing and streaming.
                                                       generator: Temple::Generators::RailsOutputBuffer,
                                                       # Disable the internal slim capturing.
                                                       # Rails takes care of the capturing by itself.
                                                       disable_capture: true,
                                                       streaming: true)
      end
    end
  end
end
