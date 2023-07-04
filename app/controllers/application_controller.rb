# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ActiveStorage::SetCurrent
  include Pagy::Backend

  before_action :sign_in_for_demo, if: -> { Docuseal.demo? }
  before_action :maybe_redirect_to_setup, unless: :signed_in?
  before_action :authenticate_user!, unless: :devise_controller?

  helper_method :button_title,
                :current_account,
                :svg_icon

  rescue_from Pagy::OverflowError do
    redirect_to request.path
  end

  def default_url_options
    Docuseal.default_url_options
  end

  private

  def sign_in_for_demo
    sign_in(User.first) unless signed_in?
  end

  def current_account
    current_user&.account
  end

  def maybe_redirect_to_setup
    redirect_to setup_index_path unless User.exists?
  end

  def button_title(title: 'Submit', disabled_with: 'Submitting', icon: nil)
    render_to_string(partial: 'shared/button_title', locals: { title:, disabled_with:, icon: })
  end

  def svg_icon(icon_name, class: '')
    render_to_string(partial: "icons/#{icon_name}", locals: { class: })
  end
end
