# frozen_string_literal: true

class ExternalAuthService
  def initialize(params)
    @params = params
  end

  def authenticate_user
    user = if @params[:account].present?
             find_or_create_user_with_account
           elsif @params[:account_group].present?
             find_or_create_user_with_account_group
           else
             raise ArgumentError, 'Either account or account_group params must be provided'
           end

    user.access_token.token
  end

  private

  def find_or_create_user_with_account
    account = Account.find_or_create_by_external_id(
      @params[:account][:external_id]&.to_i,
      name: @params[:account][:name],
      locale: @params[:account][:locale] || 'en-US',
      timezone: @params[:account][:timezone] || 'UTC'
    )

    User.find_or_create_by_external_id(
      account,
      @params[:user][:external_id]&.to_i,
      user_attributes
    )
  end

  def find_or_create_user_with_account_group
    account_group = AccountGroup.find_or_create_by_external_id(
      @params[:account_group][:external_id]&.to_s,
      name: @params[:account_group][:name]
    )

    User.find_or_create_by_external_group_id(
      account_group,
      @params[:user][:external_id]&.to_i,
      user_attributes
    )
  end

  def user_attributes
    {
      email: @params[:user][:email],
      first_name: @params[:user][:first_name],
      last_name: @params[:user][:last_name],
      role: 'admin'
    }
  end
end
