# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  class Current < ActiveSupport::CurrentAttributes
    attribute :user
  end

  def update
    super do |resource|
      Current.user = resource
    end
  end
end
