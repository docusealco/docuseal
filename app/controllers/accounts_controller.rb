# frozen_string_literal: true

class AccountsController < ApplicationController
  LOCALE_OPTIONS = {
    'en-US' => 'English (United States)',
    'en-GB' => 'English (United Kingdom)',
    'fr-FR' => 'Français',
    'es-ES' => 'Español',
    'pt-PT' => 'Português',
    'de-DE' => 'Deutsch',
    'it-IT' => 'Italiano'
  }.freeze

  before_action :load_account
  authorize_resource :account

  def show; end

  def update
    current_account.update!(account_params)

    unless Docuseal.multitenant?
      @encrypted_config = EncryptedConfig.find_or_initialize_by(account: current_account,
                                                                key: EncryptedConfig::APP_URL_KEY)
      @encrypted_config.assign_attributes(app_url_params)

      unless URI.parse(@encrypted_config.value.to_s).class.in?([URI::HTTP, URI::HTTPS])
        @encrypted_config.errors.add(:value, I18n.t('should_be_a_valid_url'))

        return render :show, status: :unprocessable_entity
      end

      @encrypted_config.save!

      Docuseal.refresh_default_url_options!
    end

    with_locale do
      redirect_to settings_account_path, notice: I18n.t('account_information_has_been_updated')
    end
  rescue ActiveRecord::RecordInvalid
    render :show, status: :unprocessable_entity
  end

  def destroy
    authorize!(:manage, current_account)

    true_user.update!(locked_at: Time.current, email: true_user.email.sub('@', '+removed@'))

    # rubocop:disable Layout/LineLength
    render turbo_stream: turbo_stream.replace(
      :account_delete_button,
      html: helpers.tag.p(I18n.t('your_account_removal_request_will_be_processed_within_2_months_please_contact_us_if_you_want_to_keep_your_account'))
    )
    # rubocop:enable Layout/LineLength
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
