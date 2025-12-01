# frozen_string_literal: true

class InvitationsController < Devise::PasswordsController
  def update
    super do |resource|
      resource.confirmed_at ||= Time.current if resource.errors.empty?

      PasswordsController::Current.user = resource
    end
  end
end
