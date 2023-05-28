# frozen_string_literal: true

class EsignSettingsController < ApplicationController
  before_action :load_encrypted_config

  def create
    attachment = ActiveStorage::Attachment.find_by!(uuid: params[:attachment_uuid])

    pdf = HexaPDF::Document.new(io: StringIO.new(attachment.download))

    pdf.signatures
  end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: EncryptedConfig::ESIGN_CERTS_KEY)
  end

  def storage_configs
    params.require(:encrypted_config).permit(value: {}).tap do |e|
      e[:value].compact_blank!
    end
  end
end
