# frozen_string_literal: true

class AccountCustomFieldsController < ApplicationController
  before_action :load_account_config, only: :create

  def create
    authorize!(:create, Template)

    @account_config.update!(account_config_params)

    render json: @account_config.value
  end

  private

  def load_account_config
    @account_config =
      AccountConfig.find_or_initialize_by(account: current_account, key: AccountConfig::TEMPLATE_CUSTOM_FIELDS_KEY)
  end

  def account_config_params
    params.permit(
      value: [[:uuid, :name, :type,
               :required, :readonly, :default_value,
               :title, :description,
               { preferences: {},
                 default_value: [],
                 options: [%i[value uuid]],
                 validation: %i[message pattern min max step],
                 areas: [%i[x y w h cell_w option_uuid]] }]]
    )
  end
end
