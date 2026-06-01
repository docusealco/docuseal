# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/digital_signature'
require_relative 'common'
require 'stringio'

describe HexaPDF::DigitalSignature::Signature::TransformParams do
  before do
    @doc = HexaPDF::Document.new
    @params = @doc.add({Type: :TransformParams})
  end

  describe "validation" do
    it "checks the /Annots field for valid values" do
      @params[:Annots] = [:Create, :Other, :Delete, :Other, :New]
      refute(@params.validate(auto_correct: false))
      @params.validate
      assert_equal([:Create, :Delete], @params[:Annots].value)
    end

    it "checks the /Form field for valid values" do
      @params[:Form] = [:Add, :Other, :Delete, :Other, :New]
      refute(@params.validate(auto_correct: false))
      @params.validate
      assert_equal([:Add, :Delete], @params[:Form].value)
    end

    it "checks the /EF field for valid values" do
      @params[:EF] = [:Create, :Other, :Delete, :Other, :New]
      refute(@params.validate(auto_correct: false))
      @params.validate
      assert_equal([:Create, :Delete], @params[:EF].value)
    end
  end
end

describe HexaPDF::DigitalSignature::Signature::SignatureReference do
  before do
    @doc = HexaPDF::Document.new
    @sigref = @doc.add({Type: :SigRef})
  end

  describe "validation" do
    it "checks the existence of the /Data field for FieldMDP transforms" do
      @sigref[:TransformMethod] = :FieldMDP
      refute(@sigref.validate)
      @sigref[:Data] = HexaPDF::Object.new('data', oid: 1)
      assert(@sigref.validate)
    end
  end
end

describe HexaPDF::DigitalSignature::Signature do
  before do
    @doc = HexaPDF::Document.new
    @sig = @doc.add({Type: :Sig, Filter: :'Adobe.PPKLite', SubFilter: :'ETSI.CAdES.detached'})

    @pdf_data = 'Some data'
    @pkcs7 = OpenSSL::PKCS7.sign(CERTIFICATES.signer_certificate, CERTIFICATES.signer_key,
                                 @pdf_data, [CERTIFICATES.ca_certificate],
                                 OpenSSL::PKCS7::DETACHED)
    @sig[:Contents] = @pkcs7.to_der
  end

  it "returns the signer name" do
    assert_equal('RSA signer', @sig.signer_name)
  end

  it "returns the signing time" do
    assert_equal(@sig.signature_handler.signing_time, @sig.signing_time)
  end

  it "returns the signing reason" do
    @sig[:Reason] = 'reason'
    assert_equal('reason', @sig.signing_reason)
  end

  it "returns the signing location" do
    @sig[:Location] = 'location'
    assert_equal('location', @sig.signing_location)
  end

  it "returns the signature type" do
    assert_equal('ETSI.CAdES.detached', @sig.signature_type)
  end

  describe "signature_handler" do
    it "returns the signature handler" do
      assert_kind_of(HexaPDF::DigitalSignature::Handler, @sig.signature_handler)
    end

    it "fails if the required handler is not available" do
      @sig[:SubFilter] = :Unknown
      assert_raises(HexaPDF::Error) { @sig.signature_handler }
    end
  end

  it "returns the signature contents" do
    @sig[:Contents] = 'hallo'
    assert_equal('hallo', @sig.contents)
  end

  describe "signed_data" do
    it "reads the specified portions of the document" do
      io = StringIO.new(MINIMAL_PDF)
      doc = HexaPDF::Document.new(io: io)
      @sig.document = doc
      @sig[:ByteRange] = [0, 400, 500, 333]
      assert_equal((MINIMAL_PDF[0, 400] << MINIMAL_PDF[500, 333]).b, @sig.signed_data)
    end

    it "works for invalid offsets" do
      doc = HexaPDF::Document.new(io: StringIO.new(MINIMAL_PDF))
      @sig.document = doc
      @sig[:ByteRange] = [0, 400, 9000, 333]
      assert_equal(MINIMAL_PDF[0, 400], @sig.signed_data)
    end

    it "fails if the document isn't associated with an existing PDF file" do
      assert_raises(HexaPDF::Error) { @sig.signed_data }
    end
  end

  it "invokes the signature handler for verification" do
    handler = Object.new
    store, kwargs = nil
    handler.define_singleton_method(:verify) do |in_store, in_kwargs|
      store, kwargs = in_store, in_kwargs
      :result
    end
    @sig.define_singleton_method(:signature_handler) { handler }
    assert_equal(:result, @sig.verify(allow_self_signed: true))
    assert_kind_of(OpenSSL::X509::Store, store)
    assert(kwargs[:allow_self_signed])
  end

  describe "perform_validation" do
    it "upgrades the version to 2.0 if the /SubFilter needs it" do
      refute(@sig.validate(auto_correct: false))
      assert(@sig.validate(auto_correct: true))
      assert_equal('2.0', @doc.version)
    end
  end
end
