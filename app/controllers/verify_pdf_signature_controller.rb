# frozen_string_literal: true

class VerifyPdfSignatureController < ApplicationController
  skip_authorization_check

  def create
    pdfs =
      params[:files].map do |file|
        HexaPDF::Document.new(io: file.open)
      end

    trusted_certs = Accounts.load_trusted_certs(current_account)

    render turbo_stream: turbo_stream.replace('result', partial: 'result',
                                                        locals: { pdfs:, files: params[:files], trusted_certs: })
  rescue HexaPDF::MalformedPDFError
    render turbo_stream: turbo_stream.replace('result', html: helpers.tag.div(I18n.t('invalid_pdf'), id: 'result'))
  end
end
