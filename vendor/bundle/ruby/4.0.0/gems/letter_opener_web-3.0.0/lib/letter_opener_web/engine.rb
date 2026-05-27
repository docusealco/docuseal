# frozen_string_literal: true

require 'letter_opener'
require 'letter_opener_web/delivery_method'

module LetterOpenerWeb
  class Engine < ::Rails::Engine
    isolate_namespace LetterOpenerWeb

    initializer 'letter_opener_web.add_delivery_method' do
      ActiveSupport.on_load :action_mailer do
        ActionMailer::Base.add_delivery_method(
          :letter_opener_web,
          LetterOpenerWeb::DeliveryMethod,
          location: LetterOpenerWeb.config.letters_location
        )
      end
    end
  end
end
