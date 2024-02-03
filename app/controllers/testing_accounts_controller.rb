# frozen_string_literal: true

class TestingAccountsController < ApplicationController
  skip_authorization_check only: :destroy

  def show
    authorize!(:manage, current_account)
    authorize!(:manage, current_user)

    impersonate_user(Accounts.find_or_create_testing_user(true_user.account))

    redirect_back(fallback_location: root_path)
  end

  def destroy
    stop_impersonating_user

    redirect_back(fallback_location: root_path)
  end
end
