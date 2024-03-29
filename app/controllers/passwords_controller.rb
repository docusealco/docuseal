# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  class Current < ActiveSupport::CurrentAttributes
    attribute :user
  end

  def create
    super do |resource|
      resource.errors.clear unless Docuseal.multitenant?
    end
  end

  def update
    super do |resource|
      Current.user = resource
    end
  end
end
