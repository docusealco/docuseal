# frozen_string_literal: true

class EsignSettingsController < ApplicationController
  def create
    blobs =
      params[:blob_signed_ids].map do |sid|
        ActiveStorage::Blob.find_signed(sid)
      end

    pdfs =
      blobs.map do |blob|
        HexaPDF::Document.new(io: StringIO.new(blob.download))
      end

    cert = EncryptedConfig.find_by(account: current_account, key: EncryptedConfig::ESIGN_CERTS_KEY).value

    trusted_certs = [OpenSSL::X509::Certificate.new(cert['cert']),
                     OpenSSL::X509::Certificate.new(cert['sub_ca']),
                     OpenSSL::X509::Certificate.new(cert['root_ca'])]

    render turbo_stream: turbo_stream.replace('result', partial: 'result', locals: { pdfs:, blobs:, trusted_certs: })
  rescue HexaPDF::MalformedPDFError
    render turbo_stream: turbo_stream.replace('result', html: helpers.tag.div('Invalid PDF', id: 'result'))
  end
end
