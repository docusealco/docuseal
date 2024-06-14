# frozen_string_literal: true

class UsersController < ApplicationController
  load_and_authorize_resource :user, only: %i[index edit update destroy]

  before_action :build_user, only: %i[new create]
  authorize_resource :user, only: %i[new create]

  def index
    @users =
      if params[:status] == 'archived'
        @users.archived
      else
        @users.active
      end

    @pagy, @users = pagy(@users.where(account: current_account).order(id: :desc))
  end

  def new; end

  def edit; end

  def create
    existing_user = User.accessible_by(current_ability).find_by(email: @user.email)

    if existing_user
      existing_user.archived_at = nil
      existing_user.assign_attributes(user_params)
      existing_user.account = current_account

      @user = existing_user
    end

    if @user.save
      UserMailer.invitation_email(@user).deliver_later!

      redirect_back fallback_location: settings_users_path, notice: 'User has been invited'
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'users/new'), status: :unprocessable_entity
    end
  end

  def update
    return redirect_to settings_users_path, notice: 'Unable to update user.' if Docuseal.demo?

    attrs = user_params.compact_blank.merge(user_params.slice(:archived_at))
    attrs.delete(:role) if !role_valid?(attrs[:role]) || current_user == @user

    if params.dig(:user, :account_id).present?
      account = Account.accessible_by(current_ability).find(params[:user][:account_id])

      authorize!(:manage, account)

      @user.account = account
    end

    if @user.update(attrs)
      redirect_back fallback_location: settings_users_path, notice: 'User has been updated'
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'users/edit'), status: :unprocessable_entity
    end
  end

  def destroy
    if Docuseal.demo? || @user.id == current_user.id
      return redirect_to settings_users_path, notice: 'Unable to remove user'
    end

    @user.update!(archived_at: Time.current)

    redirect_back fallback_location: settings_users_path, notice: 'User has been removed'
  end

  private

  def role_valid?(role)
    User::ROLES.include?(role)
  end

  def build_user
    @user = current_account.users.find_by(email: user_params[:email])&.tap do |user|
      user.assign_attributes(user_params)
      user.archived_at = nil
    end

    @user ||= current_account.users.new(user_params)

    @user
  end

  def user_params
    if params.key?(:user)
      params.require(:user).permit(:email, :first_name, :last_name, :password,
                                   :role, :archived_at, :account_id)
    else
      {}
    end
  end
end
