# frozen_string_literal: true

class UsersController < ApplicationController
  load_and_authorize_resource :user, only: %i[index edit new update destroy]

  before_action :build_user, only: :create
  authorize_resource :user, only: :create

  def index
    @pagy, @users = pagy(@users.active.order(id: :desc))
  end

  def new; end

  def edit; end

  def create
    if @user.save
      UserMailer.invitation_email(@user).deliver_later!

      redirect_to settings_users_path, notice: 'User has been invited'
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'users/new'), status: :unprocessable_entity
    end
  end

  def update
    return redirect_to settings_users_path, notice: 'Unable to update user.' if Docuseal.demo?

    attrs = user_params.compact_blank
    attrs.delete(:role) if !role_valid?(attrs[:role]) || current_user == @user

    if @user.update(attrs)
      redirect_to settings_users_path, notice: 'User has been updated'
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'users/edit'), status: :unprocessable_entity
    end
  end

  def destroy
    if Docuseal.demo? || @user.id == current_user.id
      return redirect_to settings_users_path, notice: 'Unable to remove user'
    end

    @user.update!(archived_at: Time.current)

    redirect_to settings_users_path, notice: 'User has been removed'
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
    params.require(:user).permit(:email, :first_name, :last_name, :password, :role)
  end
end
