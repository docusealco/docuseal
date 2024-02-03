# frozen_string_literal: true

class TemplateSharingsTestingController < ApplicationController
  load_and_authorize_resource :template, parent: true

  before_action do
    authorize!(:manage, TemplateSharing.new(template: @template))
  end

  def create
    testing_account = Accounts.find_or_create_testing_user(true_user.account).account

    if params[:value] == '1'
      TemplateSharing.create!(ability: :manage, account: testing_account, template: @template)
    else
      TemplateSharing.find_by(template: @template, account: testing_account)&.destroy!
    end

    head :ok
  end
end
