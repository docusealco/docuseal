# frozen_string_literal: true

class UserSignaturesController < ApplicationController
  before_action :load_user_config
  authorize_resource :user_config

  def edit; end

  def update
    file = params[:file]

    return redirect_to settings_profile_index_path, notice: I18n.t('unable_to_save_signature') if file.blank?

    blob = ActiveStorage::Blob.create_and_upload!(io: file.open,
                                                  filename: file.original_filename,
                                                  content_type: file.content_type)

    attachment = ActiveStorage::Attachment.create!(
      blob:,
      name: 'signature',
      record: current_user
    )

    if @user_config.update(value: attachment.uuid)
      redirect_to settings_profile_index_path, notice: I18n.t('signature_has_been_saved')
    else
      redirect_to settings_profile_index_path, notice: I18n.t('unable_to_save_signature')
    end
  end

  def destroy
    @user_config.destroy

    redirect_to settings_profile_index_path, notice: I18n.t('signature_has_been_removed')
  end

  private

  def load_user_config
    @user_config =
      UserConfig.find_or_initialize_by(user: current_user, key: UserConfig::SIGNATURE_KEY)
  end
end
