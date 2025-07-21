# frozen_string_literal: true

class EmailSmtpSettingsController < ApplicationController
  before_action :load_encrypted_config
  authorize_resource :encrypted_config, only: :index
  authorize_resource :encrypted_config, parent: false, only: :create

  def index; end

  def create
    # Store the original values in case of error
    original_value = @encrypted_config.value
    Rails.logger.info "SMTP Update: Original config: #{original_value.inspect}"
    
    begin
      if @encrypted_config.update(email_configs)
        unless Docuseal.multitenant?
          # Only attempt to send test email if SMTP settings are provided
          if @encrypted_config.value.present? && @encrypted_config.value['address'].present?
            SettingsMailer.smtp_successful_setup(@encrypted_config.value['from_email'] || current_user.email).deliver_now!
          end
        end

        redirect_to settings_email_index_path, notice: I18n.t('changes_have_been_saved')
        return
      else
        Rails.logger.error "SMTP Update: Update failed with errors: #{@encrypted_config.errors.full_messages}"
        render :index, status: :unprocessable_entity
        return
      end
    rescue StandardError => e
      Rails.logger.error "SMTP Update: Error occurred: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Restore the original values to prevent data loss
      @encrypted_config.value = original_value
      @encrypted_config.save if @encrypted_config.changed?
      
      flash[:alert] = "Error updating SMTP settings: #{e.message}"
      render :index, status: :unprocessable_entity
    end
  end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: EncryptedConfig::EMAIL_SMTP_KEY)
  end

  def email_configs
    params.require(:encrypted_config).permit(value: {}).tap do |e|
      e[:value].compact_blank!
    end
  end
end
