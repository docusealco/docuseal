# frozen_string_literal: true

class EsignSettingsController < ApplicationController
  def create
    pdfs =
      params[:files].map do |file|
        HexaPDF::Document.new(io: file.open)
      end

    certs = Accounts.load_signing_certs(current_account)

    trusted_certs = [certs[:cert], certs[:sub_ca], certs[:root_ca]]

    render turbo_stream: turbo_stream.replace('result', partial: 'result',
                                                        locals: { pdfs:, files: params[:files], trusted_certs: })
  rescue HexaPDF::MalformedPDFError
    render turbo_stream: turbo_stream.replace('result', html: helpers.tag.div('Invalid PDF', id: 'result'))
  end
end
