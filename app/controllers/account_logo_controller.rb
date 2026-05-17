# frozen_string_literal: true

class AccountLogoController < ApplicationController
  before_action :authorize_change

  def create
    file = params[:logo]

    return reject('Choose a file to upload.') if file.blank? || !file.respond_to?(:content_type)
    unless Account::LOGO_CONTENT_TYPES.include?(file.content_type)
      return reject('Logo must be a PNG, JPEG, or SVG image.')
    end
    if file.size > Account::LOGO_MAX_BYTES
      return reject("Logo must be under #{Account::LOGO_MAX_BYTES / 1.megabyte} MB.")
    end

    safe = AccountLogo.sanitize_upload(file)
    current_account.logo.attach(io: safe.io, filename: safe.filename, content_type: safe.content_type)

    redirect_to settings_personalization_path, notice: 'Logo updated.'
  rescue StandardError => e
    Rails.logger.warn("[AccountLogo] upload failed: #{e.class}: #{e.message}")
    reject("Couldn't save the logo: #{e.message}")
  end

  def destroy
    current_account.logo.purge if current_account.logo.attached?
    redirect_to settings_personalization_path, notice: 'Logo removed.'
  end

  private

  def authorize_change
    authorize!(:manage, current_account)
  end

  def reject(message)
    redirect_back(fallback_location: settings_personalization_path, alert: message)
  end
end
