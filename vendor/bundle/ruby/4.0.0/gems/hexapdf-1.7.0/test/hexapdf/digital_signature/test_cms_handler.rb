# -*- encoding: utf-8 -*-

require 'digest'
require 'test_helper'
require_relative 'common'
require 'hexapdf/digital_signature'

describe HexaPDF::DigitalSignature::CMSHandler do
  before do
    @data = data = 'Some data'
    @dict = Struct.new(:contents, :signed_data, :signature_type, :Reference, :M).new
    @pkcs7 = pkcs7 = OpenSSL::PKCS7.sign(CERTIFICATES.signer_certificate, CERTIFICATES.signer_key,
                                         @data, [CERTIFICATES.ca_certificate],
                                         OpenSSL::PKCS7::DETACHED)
    @dict.contents = pkcs7.to_der
    @dict.signed_data = data
    @handler = HexaPDF::DigitalSignature::CMSHandler.new(@dict)
  end

  it "fails with an appropriate error if the the signature contents is invalid" do
    @dict.contents = :Unknown
    msg = assert_raises(HexaPDF::Error) { HexaPDF::DigitalSignature::CMSHandler.new(@dict) }
    assert_match(/contents is invalid/, msg.message)
  end

  it "returns the signer name" do
    assert_equal("RSA signer", @handler.signer_name)
  end

  it "returns the signing time from the signed attributes" do
    assert_equal(@pkcs7.signers.first.signed_time, @handler.signing_time)
  end

  it "returns the certificate chain" do
    assert_equal([CERTIFICATES.signer_certificate, CERTIFICATES.ca_certificate],
                 @handler.certificate_chain)
  end

  it "returns the signer certificate" do
    assert_equal(CERTIFICATES.signer_certificate, @handler.signer_certificate)
  end

  it "allows access to the signer information" do
    info = @handler.signer_info
    assert(info)
    assert_equal(2, info.serial)
    assert_equal(CERTIFICATES.signer_certificate.issuer, info.issuer)
  end

  describe "verify" do
    before do
      @store = OpenSSL::X509::Store.new
      @store.add_cert(CERTIFICATES.ca_certificate)
    end

    it "logs an error if there are no certificates" do
      def @handler.certificate_chain; []; end
      result = @handler.verify(@store)
      assert_equal(1, result.messages.size)
      assert_equal(:error, result.messages.first.type)
      assert_match(/No certificates/, result.messages.first.content)
    end

    it "logs an error if there is more than one signer" do
      @pkcs7.add_signer(OpenSSL::PKCS7::SignerInfo.new(CERTIFICATES.signer_certificate,
                                                       CERTIFICATES.signer_key, 'SHA1'))
      @dict.contents = @pkcs7.to_der
      @handler = HexaPDF::DigitalSignature::CMSHandler.new(@dict)
      result = @handler.verify(@store)
      assert_equal(3, result.messages.size)
      assert_equal(:error, result.messages.first.type)
      assert_match(/Exactly one signer needed/, result.messages.first.content)
    end

    it "logs an error if the signer certificate is not found" do
      def @handler.signer_certificate; nil end
      result = @handler.verify(@store)
      assert_equal(1, result.messages.size)
      assert_equal(:error, result.messages.first.type)
      assert_match(/Signer.*not found/, result.messages.first.content)
    end

    it "logs an error if the signer certificate is not usable for digital signatures" do
      @pkcs7 = OpenSSL::PKCS7.sign(CERTIFICATES.ca_certificate, CERTIFICATES.ca_key,
                                   @data, [CERTIFICATES.ca_certificate],
                                   OpenSSL::PKCS7::DETACHED)
      @dict.contents = @pkcs7.to_der
      @handler = HexaPDF::DigitalSignature::CMSHandler.new(@dict)
      result = @handler.verify(@store)
      assert_equal(:error, result.messages.first.type)
      assert_match(/key usage is missing 'Digital Signature'/, result.messages.first.content)
    end

    it "provides info for a non-repudiation signature" do
      @pkcs7 = OpenSSL::PKCS7.sign(CERTIFICATES.non_repudiation_signer_certificate,
                                   CERTIFICATES.signer_key,
                                   @data, [CERTIFICATES.ca_certificate],
                                   OpenSSL::PKCS7::DETACHED)
      @dict.contents = @pkcs7.to_der
      @handler = HexaPDF::DigitalSignature::CMSHandler.new(@dict)
      result = @handler.verify(@store)
      assert_equal(:info, result.messages.first.type)
      assert_match(/Certificate used for non-repudiation/, result.messages.first.content)
    end

    it "verifies the signature itself" do
      result = @handler.verify(@store)
      assert_equal(:info, result.messages[-2].type)
      assert_match(/Signature valid/, result.messages[-2].content)

      @dict.signed_data = 'other data'
      result = @handler.verify(@store)
      assert_equal(:error, result.messages[-2].type)
      assert_match(/Signature verification failed/, result.messages[-2].content)
    end

    it "verifies a timestamp signature" do
      req = OpenSSL::Timestamp::Request.new
      req.algorithm = 'SHA256'
      req.message_imprint = Digest::SHA256.digest(@data)
      req.policy_id = "1.2.3.4.5"
      req.nonce = 42
      fac = OpenSSL::Timestamp::Factory.new
      fac.gen_time = Time.now
      fac.serial_number = 1
      fac.allowed_digests = ["sha256", "sha512"]
      res = fac.create_timestamp(CERTIFICATES.signer_key, CERTIFICATES.timestamp_certificate, req)
      @dict.contents = res.token.to_der
      @dict.signature_type = 'ETSI.RFC3161'
      @handler = HexaPDF::DigitalSignature::CMSHandler.new(@dict)

      result = @handler.verify(@store)
      assert_equal(:info, result.messages[-2].type)
      assert_match(/Signature valid/, result.messages[-2].content)
    end

    it "provides information on the certificate chain" do
      result = @handler.verify(@store)
      assert_match(/RSA signer -> HexaPDF Test Root CA/, result.messages.last.content)
    end
  end

  describe "with embedded TSA signature" do
    before do
      CERTIFICATES.start_tsa_server
      tsh = HexaPDF::DigitalSignature::Signing::TimestampHandler.new(
        signature_size: 10_000, tsa_url: 'http://127.0.0.1:34567'
      )
      cms = HexaPDF::DigitalSignature::Signing::SignedDataCreator.create(
        @data, type: :pades, certificate: CERTIFICATES.signer_certificate,
        key: CERTIFICATES.signer_key, timestamp_handler: tsh,
        certificates: [CERTIFICATES.ca_certificate]
      )
      @dict.contents = cms.to_der
      @dict.signed_data = @data
      @handler = HexaPDF::DigitalSignature::CMSHandler.new(@dict)
    end

    it "returns the signing time from the TSA signature" do
      assert_equal(@handler.embedded_tsa_signature.signers.first.signed_time, @handler.signing_time)
    end

    it "provides informational output if the time is from a TSA signature" do
      store = OpenSSL::X509::Store.new
      result = @handler.verify(store)
      assert_equal(:info, result.messages.first.type)
      assert_match(/Signing time.*timestamp authority/, result.messages.first.content)
    end
  end
end
