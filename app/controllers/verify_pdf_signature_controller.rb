# frozen_string_literal: true

class VerifyPdfSignatureController < ApplicationController
  skip_authorization_check

  def create
    trusted_certs = Accounts.load_trusted_certs(current_account)

    signatures =
      params[:files].map do |file|
        VerifyPdfSignature.call(file.open, trusted_certs)
      end

    render turbo_stream: turbo_stream.replace('result', partial: 'result',
                                                        locals: { signatures:, files: params[:files] })
  rescue Pdfium::PdfiumError
    render turbo_stream: turbo_stream.replace('result', html: helpers.tag.div(I18n.t('invalid_pdf'), id: 'result'))
  end
end
