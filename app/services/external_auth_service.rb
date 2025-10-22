# frozen_string_literal: true

class ExternalAuthService
  def initialize(params)
    @params = params
  end

  def authenticate_user
    user = if @params[:account].present?
             find_or_create_user_with_account
           elsif @params[:partnership].present?
             # Check if account context is also provided for account-level operations
             if @params[:external_account_id].present?
               find_or_create_user_with_partnership_and_account
             else
               find_or_create_user_with_partnership
             end
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
    find_or_create_user_by_external_id(account: nil)
  end

  def find_or_create_user_with_partnership_and_account
    # Hybrid approach: partnership authentication with account context
    ensure_partnerships_exist

    # Find the target account by external_account_id
    account = Account.find_by(external_account_id: @params[:external_account_id])
    raise ArgumentError, "Account not found for external_account_id: #{@params[:external_account_id]}" unless account

    find_or_create_user_by_external_id(account: account)
  end

  def ensure_partnerships_exist
    # Create the partnership if it doesn't exist in DocuSeal
    return if @params[:partnership].blank?

    Partnership.find_or_create_by_external_id(
      @params[:partnership][:external_id],
      @params[:partnership][:name]
    )
  end

  def find_or_create_user_by_external_id(account: nil)
    external_user_id = @params[:user][:external_id]&.to_i
    user = User.find_by(external_user_id: external_user_id)

    if user.present?
      # If user exists and we have an account context, assign them to the account if they don't have one
      user.update!(account: account) if account.present? && user.account_id.blank?
      return user
    end

    # Create new user
    create_attributes = user_attributes.merge(
      external_user_id: external_user_id,
      password: SecureRandom.hex(16)
    )

    create_attributes[:account] = account if account.present?

    User.create!(create_attributes)
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
