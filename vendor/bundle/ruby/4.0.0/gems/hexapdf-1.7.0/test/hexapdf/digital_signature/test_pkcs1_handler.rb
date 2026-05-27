# -*- encoding: utf-8 -*-

require 'test_helper'
require_relative 'common'
require 'hexapdf/digital_signature'

describe HexaPDF::DigitalSignature::PKCS1Handler do
  before do
    @data = 'Some data'
    @dict = Struct.new(:signed_data, :contents, :Cert, :Reference, :M).new
    @dict.signed_data = @data
    encoded_data = CERTIFICATES.signer_key.sign(OpenSSL::Digest.new('SHA1'), @data)
    @dict.contents = OpenSSL::ASN1::OctetString.new(encoded_data).to_der
    @dict.Cert = [CERTIFICATES.signer_certificate.to_der]
    def @dict.key?(*); true; end
    @handler = HexaPDF::DigitalSignature::PKCS1Handler.new(@dict)
  end

  it "returns the certificate chain" do
    assert_equal([CERTIFICATES.signer_certificate], @handler.certificate_chain)

    @dict.singleton_class.undef_method(:key?)
    def @dict.key?(*); false; end
    assert_equal([], @handler.certificate_chain)
  end

  it "returns the signer certificate" do
    assert_equal(CERTIFICATES.signer_certificate, @handler.signer_certificate)
  end

  describe "verify" do
    before do
      @store = OpenSSL::X509::Store.new
      @store.set_default_paths
      @store.purpose = OpenSSL::X509::PURPOSE_SMIME_SIGN
    end

    it "logs an error if there are no certificates" do
      def @handler.certificate_chain; []; end
      result = @handler.verify(@store)
      assert_equal(1, result.messages.size)
      assert_equal(:error, result.messages.first.type)
      assert_match(/No certificates/, result.messages.first.content)
    end

    it "logs an error if signature contents is not of the expected type" do
      @dict.contents = OpenSSL::ASN1::Boolean.new(true).to_der
      result = @handler.verify(@store)
      assert_equal(1, result.messages.size)
      assert_equal(:error, result.messages.first.type)
      assert_match(/signature object invalid/, result.messages.first.content)
    end

    it "verifies the signature itself" do
      result = @handler.verify(@store)
      assert_equal(:info, result.messages.last.type)
      assert_match(/Signature valid/, result.messages.last.content)

      @dict.signed_data = 'other data'
      result = @handler.verify(@store)
      assert_equal(:error, result.messages.last.type)
      assert_match(/Signature verification failed/, result.messages.last.content)
    end
  end
end
