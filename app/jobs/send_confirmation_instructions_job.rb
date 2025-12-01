# frozen_string_literal: true

class SendConfirmationInstructionsJob
  include Sidekiq::Job

  def perform(params = {})
    user = User.find(params['user_id'])

    user.send_confirmation_instructions
  end
end
