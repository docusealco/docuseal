# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/digital_signature'
require 'hexapdf/document'
require 'time'
require 'openssl'

describe HexaPDF::DigitalSignature::Handler do
  before do
    @time = Time.parse("2021-11-14 7:00")
    @dict = {Name: "handler", M: @time}
    @handler = HexaPDF::DigitalSignature::Handler.new(@dict)
    @result = HexaPDF::DigitalSignature::VerificationResult.new
  end

  it "returns the signer name" do
    assert_equal("handler", @handler.signer_name)
  end

  it "returns the signing time" do
    assert_equal(@time, @handler.signing_time)
  end

  it "needs an implementation of certificate_chain" do
    assert_raises(RuntimeError) { @handler.certificate_chain }
  end

  it "needs an implementation of signer_certificate" do
    assert_raises(RuntimeError) { @handler.signer_certificate }
  end

  describe "store_verification_callback" do
    before do
      @context = Struct.new(:error).new
    end

    it "can allow self-signed certificates" do
      [OpenSSL::X509::V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT,
       OpenSSL::X509::V_ERR_SELF_SIGNED_CERT_IN_CHAIN].each do |error|
        [true, false].each do |allow_self_signed|
          @result.messages.clear
          @context.error = error
          @handler.send(:store_verification_callback, @result, allow_self_signed: allow_self_signed).
            call(false, @context)
          assert_equal(1, @result.messages.size)
          assert_match(/self-signed certificate/i, @result.messages[0].content)
          assert_equal(allow_self_signed ? :info : :error, @result.messages[0].type)
        end
      end
    end
  end

  it "verifies the signing time" do
    [
      [true, '6:00', '8:00'],
      [false, '7:30', '8:00'],
      [false, '5:00', '6:00'],
    ].each do |success, not_before, not_after|
      @result.messages.clear
      @handler.define_singleton_method(:signer_certificate) do
        Struct.new(:not_before, :not_after).new.tap do |struct|
          struct.not_before = Time.parse("2021-11-14 #{not_before}")
          struct.not_after = Time.parse("2021-11-14 #{not_after}")
        end
      end
      @handler.send(:verify_signing_time, @result)
      if success
        assert(@result.messages.empty?)
      else
        assert_equal(1, @result.messages.size)
      end
      @handler.singleton_class.remove_method(:signer_certificate)
    end
  end

  describe "check_certified_signature" do
    before do
      @dict = HexaPDF::Document.new.wrap({Type: :Sig})
      @handler.instance_variable_set(:@signature_dict, @dict)
    end

    it "logs nothing if there is no signature reference dictionary" do
      @handler.send(:check_certified_signature, @result)
      assert(@result.messages.empty?)
    end

    it "logs nothing if the global DocMDP permissions entry doesn't point to the signature" do
      @dict[:Reference] = [{TransformMethod: :DocMDP}]
      @handler.send(:check_certified_signature, @result)
      assert(@result.messages.empty?)
    end

    it "logs a message if the signature is a certified one" do
      @dict[:Reference] = [{TransformMethod: :DocMDP}]
      @dict.document.catalog[:Perms] = {DocMDP: @dict}
      @handler.send(:check_certified_signature, @result)
      assert_equal(1, @result.messages.size)
      assert_match(/certified signature/i, @result.messages[0].content)
    end
  end
end
