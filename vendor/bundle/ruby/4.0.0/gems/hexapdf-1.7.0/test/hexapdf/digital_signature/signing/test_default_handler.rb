# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require_relative '../common'

describe HexaPDF::DigitalSignature::Signing::DefaultHandler do
  before do
    @doc = HexaPDF::Document.new
    @handler = HexaPDF::DigitalSignature::Signing::DefaultHandler.new(
      certificate: CERTIFICATES.signer_certificate,
      key: CERTIFICATES.signer_key,
      certificate_chain: [CERTIFICATES.ca_certificate]
    )
  end

  it "defaults to standard CMS signatures" do
    assert_equal(:cms, @handler.signature_type)
  end

  it "returns the size of serialized signature" do
    assert(@handler.signature_size > 1000)
    @handler.signature_size = 100
    assert_equal(100, @handler.signature_size)
  end

  it "allows setting the DocMDP permissions" do
    assert_nil(@handler.doc_mdp_permissions)

    @handler.doc_mdp_permissions = :no_changes
    assert_equal(1, @handler.doc_mdp_permissions)
    @handler.doc_mdp_permissions = 1
    assert_equal(1, @handler.doc_mdp_permissions)

    @handler.doc_mdp_permissions = :form_filling
    assert_equal(2, @handler.doc_mdp_permissions)
    @handler.doc_mdp_permissions = 2
    assert_equal(2, @handler.doc_mdp_permissions)

    @handler.doc_mdp_permissions = :form_filling_and_annotations
    assert_equal(3, @handler.doc_mdp_permissions)
    @handler.doc_mdp_permissions = 3
    assert_equal(3, @handler.doc_mdp_permissions)

    @handler.doc_mdp_permissions = nil
    assert_nil(@handler.doc_mdp_permissions)

    assert_raises(ArgumentError) { @handler.doc_mdp_permissions = :other }
  end

  describe "sign" do
    it "can sign the data using the provided certificate and key" do
      data = StringIO.new("data")
      signed_data = @handler.sign(data, [0, data.string.size, 0, 0])

      pkcs7 = OpenSSL::PKCS7.new(signed_data)
      assert(pkcs7.detached?)
      assert_equal([CERTIFICATES.signer_certificate, CERTIFICATES.ca_certificate],
                   pkcs7.certificates)
      store = OpenSSL::X509::Store.new
      store.add_cert(CERTIFICATES.ca_certificate)
      assert(pkcs7.verify([], store, data.string, OpenSSL::PKCS7::DETACHED | OpenSSL::PKCS7::BINARY))
    end

    it "can change the used digest algorithm" do
      @handler.digest_algorithm = 'sha384'
      asn1 = OpenSSL::ASN1.decode(@handler.sign(StringIO.new('data'), [0, 4, 0, 0]))
      assert_equal('SHA384', asn1.value[1].value[0].value[1].value[0].value[0].value)
    end

    it "can embed a timestamp token" do
      @handler.timestamp_handler = tsh = Object.new
      tsh.define_singleton_method(:sign) {|_, _| OpenSSL::ASN1::OctetString.new("signed-tsh") }
      signed = @handler.sign(StringIO.new('data'), [0, 4, 0, 0])
      asn1 = OpenSSL::ASN1.decode(signed)
      assert_equal('signed-tsh', asn1.value[1].value[0].value[4].value[0].
                   value[6].value[0].value[1].value[0].value)
    end

    it "creates PAdES compatible signatures" do
      @handler.signature_type = :pades
      signed = @handler.sign(StringIO.new('data'), [0, 4, 0, 0])
      asn1 = OpenSSL::ASN1.decode(signed)
      # check by absence of signing-time signed attribute
      refute(asn1.value[1].value[0].value[4].value[0].value[3].value.
             find {|obj| obj.value[0].value == 'signingTime' })
    end

    it "can use external signing without certificate set" do
      @handler.certificate = nil
      @handler.external_signing = proc { "hallo" }
      assert_equal("hallo", @handler.sign(StringIO.new, [0, 0, 0, 0]))
    end

    it "can use external signing with certificate set but not the key" do
      @handler.key = nil
      @handler.external_signing = proc do |algorithm, _hash|
        assert_equal('sha256', algorithm)
        "hallo"
      end
      result = @handler.sign(StringIO.new, [0, 0, 0, 0])
      asn1 = OpenSSL::ASN1.decode(result)
      assert_equal("hallo", asn1.value[1].value[0].value[4].value[0].value[5].value)
    end
  end

  describe "finalize_objects" do
    before do
      @field = @doc.wrap({})
      @obj = @doc.wrap({})
    end

    it "only sets the mandatory values if no concrete finalization tasks need to be done" do
      @handler.finalize_objects(@field, @obj)
      assert(@field.empty?)
      assert_equal(:'Adobe.PPKLite', @obj[:Filter])
      assert_equal(:'adbe.pkcs7.detached', @obj[:SubFilter])
      assert_kind_of(Time, @obj[:M])
    end

    it "adjust the /SubFilter if signature type is pades" do
      @handler.signature_type = :pades
      @handler.finalize_objects(@field, @obj)
      assert_equal(:'ETSI.CAdES.detached', @obj[:SubFilter])
    end

    it "sets the reason, location and contact info fields" do
      @handler.reason = 'Reason'
      @handler.location = 'Location'
      @handler.contact_info = 'Contact'
      @handler.finalize_objects(@field, @obj)
      assert(@field.empty?)
      assert_equal(['Reason', 'Location', 'Contact'], @obj.value.values_at(:Reason, :Location, :ContactInfo))
    end

    it "sets the signing time" do
      time = Time.now
      @handler.signing_time = time
      @handler.finalize_objects(@field, @obj)
      assert_equal(time, @obj[:M])
    end

    it "fills the build properties dictionary with appropriate application information" do
      @handler.finalize_objects(@field, @obj)
      assert_equal(:HexaPDF, @obj[:Prop_Build][:App][:Name])
      assert_equal(HexaPDF::VERSION, @obj[:Prop_Build][:App][:REx])
    end

    it "applies the specified DocMDP permissions" do
      @handler.doc_mdp_permissions = :no_changes
      @handler.finalize_objects(@field, @obj)
      ref = @obj[:Reference][0]
      assert_equal(:DocMDP, ref[:TransformMethod])
      assert_equal(1, ref[:TransformParams][:P])
      assert_equal(:'1.2', ref[:TransformParams][:V])
      assert_same(@obj, @doc.catalog[:Perms][:DocMDP])
    end

    it "updates the document version if :pades signing is used" do
      @handler.signature_type = :pades
      @handler.finalize_objects(@field, @obj)
      assert_equal('2.0', @doc.version)
    end

    it "fails if DocMDP should be set but there is already a signature" do
      @handler.doc_mdp_permissions = :no_changes
      2.times do
        field = @doc.acro_form(create: true).create_signature_field('test')
        field.field_value = :something
      end
      assert_raises(HexaPDF::Error) { @handler.finalize_objects(@field, @obj) }
    end
  end
end
