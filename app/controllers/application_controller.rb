# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ActiveStorage::SetCurrent

  before_action :maybe_redirect_to_setup, unless: :signed_in?
  before_action :authenticate_user!, unless: :devise_controller?

  helper_method :button_title,
                :current_account

  private

  def current_account
    current_user&.account
  end

  def maybe_redirect_to_setup
    redirect_to setup_index_path unless User.exists?
  end

  def button_title(title = 'Submit', disabled_with = 'Submitting...')
    render_to_string(partial: 'shared/button_title', locals: { title:, disabled_with: })
  end
end
