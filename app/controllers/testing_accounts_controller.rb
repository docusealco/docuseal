# frozen_string_literal: true

class TestingAccountsController < ApplicationController
  skip_authorization_check only: :destroy

  def create
    authorize!(:manage, current_account)
    authorize!(:manage, current_user)
    authorize!(:manage, EncryptedConfig)

    impersonate_user(Accounts.find_or_create_testing_user(true_user.account))

    redirect_after_toggle
  end

  def destroy
    stop_impersonating_user

    redirect_after_toggle
  end

  private

  def redirect_after_toggle
    if turbo_native_app?
      redirect_to root_path
    else
      redirect_back(fallback_location: root_path)
    end
  end
end
