# frozen_string_literal: true

module Api
  class ToolsController < ApiBaseController
    skip_authorization_check

    def merge
      files = params[:files] || []

      return render json: { error: 'Files are required' }, status: :unprocessable_content if files.blank?
      return render json: { error: 'At least 2 files are required' }, status: :unprocessable_content if files.size < 2

      render json: {
        data: Base64.encode64(PdfUtils.merge(files.map { |base64| StringIO.new(Base64.decode64(base64)) }).string)
      }
    end

    def verify
      file = Base64.decode64(params[:file])

      trusted_certs = Accounts.load_trusted_certs(current_account)
      is_checksum_found = CompletedDocument.exists?(sha256: Base64.urlsafe_encode64(Digest::SHA256.digest(file)))

      render json: {
        checksum_status: is_checksum_found ? 'verified' : 'not_found',
        signatures: VerifyPdfSignature.call(StringIO.new(file), trusted_certs).map do |sig|
          {
            verification_result: sig.messages.map { |m| { type: m.status || :info, content: m.text } },
            signer_name: sig.common_name,
            signing_reason: sig.reason,
            signing_time: sig.signing_time,
            signature_type: sig.type
          }
        end
      }
    rescue Pdfium::PdfiumError
      render json: { error: 'Malformed PDF' }, status: :unprocessable_content
    end
  end
end
