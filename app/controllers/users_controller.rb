# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :load_user, only: %i[edit update destroy]

  def index
    @pagy, @users = pagy(current_account.users.active.order(id: :desc))
  end

  def new
    @user = current_account.users.new
  end

  def edit; end

  def create
    @user = current_account.users.find_by(email: user_params[:email])&.tap do |user|
      user.assign_attributes(user_params)
      user.deleted_at = nil
    end

    @user ||= current_account.users.new(user_params)

    if @user.save
      UserMailer.invitation_email(@user).deliver_later!

      redirect_to settings_users_path, notice: 'User has been invited.'
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'users/new'), status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params.compact_blank)
      redirect_to settings_users_path, notice: 'User has been updated.'
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'users/edit'), status: :unprocessable_entity
    end
  end

  def destroy
    @user.update!(deleted_at: Time.current)

    redirect_to settings_users_path, notice: 'User has been removed.'
  end

  private

  def load_user
    @user = current_account.users.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :first_name, :last_name, :password)
  end
end
