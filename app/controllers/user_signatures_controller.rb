# frozen_string_literal: true

class UserSignaturesController < ApplicationController
  before_action :load_user_config
  authorize_resource :user_config

  def edit
    @font_config =
      UserConfig.find_or_initialize_by(user: current_user, key: UserConfig::SIGNATURE_FONT_KEY)
  end

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
      save_font_preference(UserConfig::SIGNATURE_FONT_KEY)
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

  def save_font_preference(key)
    return if params[:font].blank?

    font_config = UserConfig.find_or_initialize_by(user: current_user, key:)
    font_config.update(value: params[:font])
  end
end
