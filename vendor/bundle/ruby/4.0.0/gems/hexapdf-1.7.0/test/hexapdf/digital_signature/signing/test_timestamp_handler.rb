# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require_relative '../common'

describe HexaPDF::DigitalSignature::Signing::TimestampHandler do
  before do
    @doc = HexaPDF::Document.new
    @handler = HexaPDF::DigitalSignature::Signing::TimestampHandler.new
  end

  it "allows setting the attributes in the constructor" do
    handler = @handler.class.new(
      tsa_url: "url", tsa_hash_algorithm: "MD5", tsa_policy_id: "5",
      reason: "Reason", location: "Location", contact_info: "Contact",
      signature_size: 1_000
    )
    assert_equal("url", handler.tsa_url)
    assert_equal("MD5", handler.tsa_hash_algorithm)
    assert_equal("5", handler.tsa_policy_id)
    assert_equal("Reason", handler.reason)
    assert_equal("Location", handler.location)
    assert_equal("Contact", handler.contact_info)
    assert_equal(1_000, handler.signature_size)
  end

  it "finalizes the signature field and signature objects" do
    @field = @doc.wrap({})
    @sig = @doc.wrap({})
    @handler.reason = 'Reason'
    @handler.location = 'Location'
    @handler.contact_info = 'Contact'

    @handler.finalize_objects(@field, @sig)
    assert_equal('2.0', @doc.version)
    assert_equal(:DocTimeStamp, @sig[:Type])
    assert_equal(:'Adobe.PPKLite', @sig[:Filter])
    assert_equal(:'ETSI.RFC3161', @sig[:SubFilter])
    assert_equal('Reason', @sig[:Reason])
    assert_equal('Location', @sig[:Location])
    assert_equal('Contact', @sig[:ContactInfo])
  end

  it "returns the size of serialized signature" do
    @handler.tsa_url = "http://127.0.0.1:34567"
    CERTIFICATES.start_tsa_server
    assert(@handler.signature_size > 1000)
  end

  describe "sign" do
    before do
      @data = StringIO.new("data")
      @range = [0, 4, 0, 0]
      @handler.tsa_url = "http://127.0.0.1:34567"
      CERTIFICATES.start_tsa_server
    end

    it "respects the set hash algorithm and policy id" do
      @handler.tsa_hash_algorithm = 'SHA256'
      @handler.tsa_policy_id = '1.2.3.4.2'
      token = OpenSSL::ASN1.decode(@handler.sign(@data, @range))
      content = OpenSSL::ASN1.decode(token.value[1].value[0].value[2].value[1].value[0].value)
      policy_id = content.value[1].value
      digest_algorithm = content.value[2].value[0].value[0].value
      assert_equal('SHA256', digest_algorithm)
      assert_equal("1.2.3.4.2", policy_id)
    end

    it "allows using basic authentication on the server" do
      @handler.tsa_policy_id = '1.2.3.4.3'
      @handler.tsa_username = 'hexatest'
      @handler.tsa_password = 'invalid'
      msg = assert_raises(HexaPDF::Error) { @handler.sign(@data, @range) }
      assert_match(/Basic authentication/, msg.message)

      @handler.tsa_password = 'hexapwd'
      token = OpenSSL::PKCS7.new(@handler.sign(@data, @range))
      assert_equal(CERTIFICATES.ca_certificate.subject, token.signers[0].issuer)
    end

    it "returns the serialized timestamp token" do
      token = OpenSSL::PKCS7.new(@handler.sign(@data, @range))
      assert_equal(CERTIFICATES.ca_certificate.subject, token.signers[0].issuer)
      assert_equal(CERTIFICATES.timestamp_certificate.serial, token.signers[0].serial)
    end

    it "fails if the timestamp token could not be created" do
      @handler.tsa_hash_algorithm = 'SHA1'
      msg = assert_raises(HexaPDF::Error) { @handler.sign(@data, @range) }
      assert_match(/BAD_ALG/, msg.message)
    end

    it "fails if the timestamp server couldn't process the request" do
      @handler.tsa_policy_id = '1.2.3.4.1'
      msg = assert_raises(HexaPDF::Error) { @handler.sign(@data, @range) }
      assert_match(/Invalid TSA server response/, msg.message)
    end
  end
end
