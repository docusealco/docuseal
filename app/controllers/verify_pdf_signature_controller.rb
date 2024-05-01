# frozen_string_literal: true

class VerifyPdfSignatureController < ApplicationController
  skip_authorization_check

  def create
    pdfs =
      params[:files].map do |file|
        HexaPDF::Document.new(io: file.open)
      end

    cert_data =
      if Docuseal.multitenant?
        value = EncryptedConfig.find_by(account: current_account, key: EncryptedConfig::ESIGN_CERTS_KEY)&.value || {}

        Docuseal::CERTS.merge(value)
      else
        EncryptedConfig.find_by(key: EncryptedConfig::ESIGN_CERTS_KEY)&.value || {}
      end

    default_pkcs = GenerateCertificate.load_pkcs(cert_data)

    custom_certs = cert_data.fetch('custom', []).map do |e|
      OpenSSL::PKCS12.new(Base64.urlsafe_decode64(e['data']), e['password'].to_s)
    end

    trusted_certs = [default_pkcs.certificate,
                     *default_pkcs.ca_certs,
                     *custom_certs.map(&:certificate),
                     *custom_certs.flat_map(&:ca_certs).compact,
                     *Docuseal.trusted_certs]

    render turbo_stream: turbo_stream.replace('result', partial: 'result',
                                                        locals: { pdfs:, files: params[:files], trusted_certs: })
  rescue HexaPDF::MalformedPDFError
    render turbo_stream: turbo_stream.replace('result', html: helpers.tag.div('Invalid PDF', id: 'result'))
  end
end
