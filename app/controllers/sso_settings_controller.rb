# frozen_string_literal: true

class SsoSettingsController < ApplicationController
  before_action :load_encrypted_config
  authorize_resource :encrypted_config, only: :index
  authorize_resource :encrypted_config, parent: false, only: :create

  def index; end

  def create
    new_value = build_sso_value

    if @encrypted_config.update(value: new_value)
      redirect_to settings_sso_index_path, notice: I18n.t('changes_have_been_saved')
    else
      render :index, status: :unprocessable_content
    end
  rescue StandardError => e
    flash[:alert] = e.message
    render :index, status: :unprocessable_content
  end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account,
                                            key: EncryptedConfig::GOOGLE_SSO_KEY)
  end

  def build_sso_value
    submitted = params.require(:encrypted_config).permit(value: {})[:value].to_h
    existing = @encrypted_config.value || {}

    # Don't clobber the saved secret with a blank one — the field is
    # rendered empty (we never echo it back) so an unchanged form would
    # otherwise wipe it out.
    submitted['client_secret'] = existing['client_secret'] if submitted['client_secret'].to_s.empty?

    submitted['allowed_domains'] =
      submitted.delete('allowed_domains_csv').to_s.split(',').map(&:strip).reject(&:empty?)

    submitted['enabled'] = submitted['enabled'].to_s == '1' || submitted['enabled'].to_s == 'true'

    submitted.compact
  end
end
