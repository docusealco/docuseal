# frozen_string_literal: true

module VerifyPdfSignature
  COMMON_NAME = 'CN'
  TIME_FORMAT = '%Y%m%d%H%M%S%z'

  SignatureStruct = Struct.new(:messages, :reason, :signing_time, :common_name, :type)
  MessageStruct = Struct.new(:text, :status)

  module_function

  def call(io, trusted_certs)
    Pdfium.with_instance do
      Pdfium::Document.open_io(io) do |document|
        signatures = document.signatures.select { |e| e.byte_range.any?(&:positive?) && e.contents.present? }

        next [] if signatures.blank?

        verified_signatures = signatures.select { |e| verified_signature?(e, io, trusted_certs) }
        trusted_signatures = verified_signatures.select { |e| trusted_signature?(e, trusted_certs) }
        last_signature = (trusted_signatures.presence || verified_signatures).max_by(&:signed_end)
        has_unsigned_changes = last_signature && unsigned_changes?(document, io, last_signature.signed_end)

        signatures.map do |signature|
          build_signature(signature, trusted_certs,
                          verified: verified_signatures.include?(signature),
                          has_unsigned_changes: has_unsigned_changes && signature == last_signature)
        end
      end
    end
  end

  def verified_signature?(signature, io, trusted_certs)
    return false unless covers_signed_revision?(signature, io)

    pkcs7 = OpenSSL::PKCS7.new(signature.contents)

    if signature.sub_filter == 'ETSI.RFC3161'
      verify_timestamp(pkcs7, signed_data(io, signature.byte_range))
    else
      verify_contents(pkcs7, signed_data(io, signature.byte_range), trusted_certs)
    end
  rescue OpenSSL::PKCS7::PKCS7Error, OpenSSL::Timestamp::TimestampError
    false
  end

  def verify_timestamp(pkcs7, signed_data)
    return false unless pkcs7.verify(pkcs7.certificates, OpenSSL::X509::Store.new, nil,
                                     OpenSSL::PKCS7::NOVERIFY | OpenSSL::PKCS7::BINARY)

    token_info = OpenSSL::Timestamp::TokenInfo.new(pkcs7.data)

    token_info.message_imprint == OpenSSL::Digest.digest(token_info.algorithm, signed_data)
  end

  def build_signature(signature, trusted_certs, verified:, has_unsigned_changes:)
    pkcs7 = OpenSSL::PKCS7.new(signature.contents)

    SignatureStruct.new(
      messages: build_messages(pkcs7, verified, trusted_certs, has_unsigned_changes),
      reason: signature.reason,
      signing_time: signing_time(pkcs7, signature),
      common_name: common_name(pkcs7),
      type: signature.sub_filter
    )
  rescue OpenSSL::PKCS7::PKCS7Error
    SignatureStruct.new(
      messages: [MessageStruct.new(text: I18n.t('signature_verification_failed'), status: :error)],
      reason: signature.reason,
      signing_time: parse_time(signature.time),
      type: signature.sub_filter
    )
  end

  def build_messages(pkcs7, verified, trusted_certs, has_unsigned_changes)
    messages =
      if verified
        [MessageStruct.new(text: I18n.t('signature_valid'), status: :success),
         certificate_message(pkcs7, trusted_certs)]
      else
        [MessageStruct.new(text: I18n.t('signature_verification_failed'), status: :error)]
      end

    if has_unsigned_changes
      messages << MessageStruct.new(text: I18n.t('contains_unsigned_changes_after_the_last_signature'),
                                    status: :warning)
    end

    messages << MessageStruct.new(text: "Certificate chain: #{certificate_chain(pkcs7).join(' -> ')}")
  end

  def certificate_message(pkcs7, trusted_certs)
    if trusted_certificate?(pkcs7, trusted_certs)
      MessageStruct.new(text: I18n.t('signed_with_trusted_certificate'), status: :success)
    else
      MessageStruct.new(text: I18n.t('signed_with_external_certificate'), status: :error)
    end
  end

  def trusted_signature?(signature, trusted_certs)
    trusted_certificate?(OpenSSL::PKCS7.new(signature.contents), trusted_certs)
  rescue OpenSSL::PKCS7::PKCS7Error
    false
  end

  def trusted_certificate?(pkcs7, trusted_certs)
    public_key = signer_certificate(pkcs7)&.public_key&.to_der

    trusted_certs.any? { |e| e.public_key.to_der == public_key }
  end

  def verify_contents(pkcs7, signed_data, trusted_certs)
    return false if digest_algorithms(pkcs7).blank?

    store = OpenSSL::X509::Store.new
    store.set_default_paths
    store.purpose = OpenSSL::X509::PURPOSE_SMIME_SIGN
    store.verify_callback = ->(_success, _context) { true }
    trusted_certs.each { |cert| store.add_cert(cert) }

    pkcs7.verify(pkcs7.certificates, store, signed_data,
                 OpenSSL::PKCS7::DETACHED | OpenSSL::PKCS7::BINARY)
  end

  def digest_algorithms(pkcs7)
    OpenSSL::ASN1.decode(pkcs7.to_der).value[1].value[0].value[1].value
  end

  def common_name(pkcs7)
    cert = signer_certificate(pkcs7)

    return if cert.nil?

    cert.subject.to_a.assoc(COMMON_NAME)&.dig(1)
  end

  def signer_certificate(pkcs7)
    info = pkcs7.signers.first

    pkcs7.certificates&.find { |cert| cert.issuer == info.issuer && cert.serial == info.serial }
  end

  def certificate_chain(pkcs7)
    signer = signer_certificate(pkcs7)

    return [] if signer.nil?

    certs = [signer]

    while (issuer = pkcs7.certificates.find { |cert| cert.subject == certs.last.issuer })
      break if certs.include?(issuer)

      certs << issuer
    end

    certs.map { |cert| cert.subject.to_a.assoc(COMMON_NAME)&.dig(1) }
  end

  def signing_time(pkcs7, signature)
    cms_signing_time(pkcs7) || parse_time(signature.time)
  end

  def cms_signing_time(pkcs7)
    pkcs7.signers.first&.signed_time
  rescue StandardError
    nil
  end

  def parse_time(value)
    return if value.blank?

    time = value.delete("'").delete_prefix('D:')
    offset = time[14..].to_s

    Time.strptime("#{time.first(14)}#{offset.start_with?('+', '-') ? offset : '+0000'}", TIME_FORMAT)
  end

  def covers_signed_revision?(signature, io)
    byte_range = signature.byte_range

    return false if byte_range.size != 4 || byte_range.any?(&:negative?) || byte_range[0].positive?
    return false if signature.signed_end > io.size

    byte_range[2] == byte_range[1] + (signature.contents.bytesize * 2) + 2
  end

  def unsigned_changes?(document, io, signed_end)
    return false if document.trailer_ends.none? { |offset| offset > signed_end }

    io.seek(0)

    Pdfium::Document.open_bytes(io.read(signed_end)) do |signed_document|
      !document.only_dss_changes?(signed_document)
    end
  end

  def signed_data(io, byte_range)
    byte_range.each_slice(2).map do |offset, length|
      io.seek(offset)
      io.read(length.clamp(0, [io.size - offset, 0].max))
    end.join
  end
end
