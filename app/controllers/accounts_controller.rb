# frozen_string_literal: true

class AccountsController < ApplicationController
  LOCALE_OPTIONS = {
    'en-US' => 'English (United States)',
    'en-GB' => 'English (United Kingdom)',
    'fr-FR' => 'French (France)',
    'es-ES' => 'Spanish (Spain)',
    'pt-PT' => 'Portuguese (Portugal)',
    'de-DE' => 'German (Germany)',
    'it-IT' => 'Italian (Italy)'
  }.freeze

  before_action :load_account
  authorize_resource :account

  def show; end

  def update
    current_account.update!(account_params)

    @encrypted_config = EncryptedConfig.find_or_initialize_by(account: current_account,
                                                              key: EncryptedConfig::APP_URL_KEY)
    @encrypted_config.assign_attributes(app_url_params)

    unless URI.parse(@encrypted_config.value.to_s).class.in?([URI::HTTP, URI::HTTPS])
      @encrypted_config.errors.add(:value, 'should be a valid URL')

      return render :show, status: :unprocessable_entity
    end

    @encrypted_config.save!

    Docuseal.refresh_default_url_options!

    redirect_to settings_account_path, notice: 'Account information has been updated'
  rescue ActiveRecord::RecordInvalid
    render :show, status: :unprocessable_entity
  end

  def destroy
    authorize!(:manage, current_account)

    true_user.update!(locked_at: Time.current)

    render turbo_stream: turbo_stream.replace(
      :account_delete_button,
      html: helpers.tag.p('Your account removal request will be processed within 2 weeks. ' \
                          'Please contact us if you want to keep your account.')
    )
  end

  private

  def load_account
    @account = current_account
  end

  def account_params
    params.require(:account).permit(:name, :timezone, :locale)
  end

  def app_url_params
    return {} if params[:encrypted_config].blank?

    params.require(:encrypted_config).permit(:value)
  end
end
