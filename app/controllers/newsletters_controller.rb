# frozen_string_literal: true

class NewslettersController < ApplicationController
  skip_authorization_check

  def show; end

  def update
    Faraday.post(Docuseal::NEWSLETTER_URL, newsletter_params.to_json, 'Content-Type' => 'application/json')
  rescue StandardError => e
    Rails.logger.error(e)
  ensure
    redirect_to root_path
  end

  private

  def newsletter_params
    params.require(:user).permit(:email)
  end
end
