# frozen_string_literal: true

class ExternalAuthService
  def initialize(params)
    @params = params
  end

  def authenticate_user
    user = if @params[:account].present?
             find_or_create_user_with_account
           elsif @params[:partnership].present?
             find_or_create_user_with_partnership
           else
             raise ArgumentError, 'Either account or partnership params must be provided'
           end

    user.access_token.token
  end

  private

  def find_or_create_user_with_account
    account = Account.find_or_create_by_external_id(
      @params[:account][:external_id]&.to_i,
      @params[:account][:name],
      {
        locale: @params[:account][:locale] || 'en-US',
        timezone: @params[:account][:timezone] || 'UTC'
      }
    )

    User.find_or_create_by_external_id(
      account,
      @params[:user][:external_id]&.to_i,
      user_attributes
    )
  end

  def find_or_create_user_with_partnership
    # Ensure partnerships exist in DocuSeal before creating the user
    # We need these partnerships to exist for templates and authorization to work
    ensure_partnerships_exist

    # For partnership users, we don't store any partnership relationship
    # They get authorized via API request context (accessible_partnership_ids)
    # Just ensure the user exists in DocuSeal for authentication
    User.find_by(external_user_id: @params[:user][:external_id]&.to_i) ||
      User.create!(
        user_attributes.merge(
          external_user_id: @params[:user][:external_id]&.to_i,
          password: SecureRandom.hex(16)
          # NOTE: No account_id or partnership_id - authorization comes from API context
        )
      )
  end

  def ensure_partnerships_exist
    # Create the partnership if it doesn't exist in DocuSeal
    return if @params[:partnership].blank?

    Partnership.find_or_create_by_external_id(
      @params[:partnership][:external_id],
      @params[:partnership][:name]
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
