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

    certs = Accounts.load_signing_certs(current_account)

    trusted_certs = [certs[:cert], certs[:sub_ca], certs[:root_ca]]

    render turbo_stream: turbo_stream.replace('result', partial: 'result', locals: { pdfs:, blobs:, trusted_certs: })
  rescue HexaPDF::MalformedPDFError
    render turbo_stream: turbo_stream.replace('result', html: helpers.tag.div('Invalid PDF', id: 'result'))
  end
end
