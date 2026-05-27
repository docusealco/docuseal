# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require_relative '../common'

describe HexaPDF::DigitalSignature::Signing::SignedDataCreator do
  before do
    @klass = HexaPDF::DigitalSignature::Signing::SignedDataCreator
    @signed_data = @klass.new
    @signed_data.certificate = CERTIFICATES.signer_certificate
    @signed_data.key = CERTIFICATES.signer_key
    @signed_data.certificates = [CERTIFICATES.ca_certificate]
  end

  it "allows setting the attributes" do
    obj = @klass.new
    obj.certificate = :cert
    obj.key = :key
    obj.certificates = :certs
    obj.digest_algorithm = 'sha512'
    obj.timestamp_handler = :tsh
    assert_equal(:cert, obj.certificate)
    assert_equal(:key, obj.key)
    assert_equal(:certs, obj.certificates)
    assert_equal('sha512', obj.digest_algorithm)
    assert_equal(:tsh, obj.timestamp_handler)
  end

  it "doesn't allow setting attributes to nil using ::create" do
    asn1 = @klass.create("data",
                         certificate: CERTIFICATES.signer_certificate,
                         key: CERTIFICATES.signer_key,
                         digest_algorithm: nil)
    assert_equal('2.16.840.1.101.3.4.2.1', asn1.value[1].value[1].value[0].value[0].value)
  end

  describe "content info structure" do
    it "sets the correct content type value for the outer container" do
      asn1 = @signed_data.create("data")
      assert_equal('1.2.840.113549.1.7.2', asn1.value[0].value)
    end

    it "has the signed data structure marked as explicit" do
      asn1 = @signed_data.create("data")
      signed_data = asn1.value[1]
      assert_equal(0, signed_data.tag)
      assert_equal(:EXPLICIT, signed_data.tagging)
      assert_equal(:CONTEXT_SPECIFIC, signed_data.tag_class)
    end
  end

  describe "signed data structure" do
    before do
      @structure = @signed_data.create("data").value[1]
    end

    it "sets the correct version" do
      assert_equal(1, @structure.value[0].value)
    end

    it "contains a reference to the used digest algorithm" do
      assert_equal('2.16.840.1.101.3.4.2.1', @structure.value[1].value[0].value[0].value)
      assert_nil(@structure.value[1].value[0].value[1].value)
    end

    it "contains an empty encapsulated content structure" do
      assert_equal(1, @structure.value[2].value.size)
      assert_equal('1.2.840.113549.1.7.1', @structure.value[2].value[0].value)
    end

    it "contains the assigned certificates" do
      assert_equal(2, @structure.value[3].value.size)
      assert_equal(0, @structure.value[3].tag)
      assert_equal(:IMPLICIT, @structure.value[3].tagging)
      assert_equal(:CONTEXT_SPECIFIC, @structure.value[3].tag_class)
      assert_equal([CERTIFICATES.signer_certificate, CERTIFICATES.ca_certificate],
                   @structure.value[3].value)
    end

    it "contains a single signer info structure" do
      assert_equal(1, @structure.value[4].value.size)
    end
  end

  describe "signer info" do
    before do
      @structure = @signed_data.create("data").value[1].value[4].value[0]
    end

    it "has the expected number of entries" do
      assert_equal(6, @structure.value.size)
    end

    it "sets the correct version" do
      assert_equal(1, @structure.value[0].value)
    end

    it "uses issuer and serial for the signer identifer" do
      assert_equal(CERTIFICATES.signer_certificate.issuer, @structure.value[1].value[0])
      assert_equal(CERTIFICATES.signer_certificate.serial, @structure.value[1].value[1].value)
    end

    it "contains a reference to the used digest algorithm" do
      assert_equal('2.16.840.1.101.3.4.2.1', @structure.value[2].value[0].value)
      assert_nil(@structure.value[2].value[1].value)
    end

    describe "signed attributes" do
      it "uses the correct tagging for the attributes" do
        assert_equal(0, @structure.value[3].tag)
        assert_equal(:IMPLICIT, @structure.value[3].tagging)
        assert_equal(:CONTEXT_SPECIFIC, @structure.value[3].tag_class)
      end

      it "contains the content type identifier" do
        attr = @structure.value[3].value.find {|obj| obj.value[0].value == '1.2.840.113549.1.9.3' }
        assert_equal('1.2.840.113549.1.7.1', attr.value[1].value[0].value)
      end

      it "contains the message digest attribute" do
        attr = @structure.value[3].value.find {|obj| obj.value[0].value == '1.2.840.113549.1.9.4' }
        assert_equal(OpenSSL::Digest.digest('SHA256', 'data'), attr.value[1].value[0].value)
      end

      it "contains the signing certificate attribute" do
        attr = @structure.value[3].value.find {|obj| obj.value[0].value == '1.2.840.113549.1.9.16.2.47' }
        signing_cert = attr.value[1].value[0]
        assert_equal(1, signing_cert.value.size)
        assert_equal(1, signing_cert.value[0].value.size)
        assert_equal(2, signing_cert.value[0].value[0].value.size)
        assert_equal(OpenSSL::Digest.digest('sha256', CERTIFICATES.signer_certificate.to_der),
                     signing_cert.value[0].value[0].value[0].value)
        assert_equal(2, signing_cert.value[0].value[0].value[1].value.size)
        assert_equal(1, signing_cert.value[0].value[0].value[1].value[0].value.size)
        assert_equal(1, signing_cert.value[0].value[0].value[1].value[0].value[0].value.size)
        assert_equal(4, signing_cert.value[0].value[0].value[1].value[0].value[0].tag)
        assert_equal(:IMPLICIT, signing_cert.value[0].value[0].value[1].value[0].value[0].tagging)
        assert_equal(:CONTEXT_SPECIFIC, signing_cert.value[0].value[0].value[1].value[0].value[0].tag_class)
        assert_equal(CERTIFICATES.signer_certificate.issuer,
                     signing_cert.value[0].value[0].value[1].value[0].value[0].value[0])
        assert_equal(CERTIFICATES.signer_certificate.serial,
                     signing_cert.value[0].value[0].value[1].value[1].value)
      end
    end

    it "contains the signature algorithm reference" do
      assert_equal('1.2.840.113549.1.1.1', @structure.value[4].value[0].value)
      assert_nil(@structure.value[4].value[1].value)
    end

    it "contains the signature itself" do
      to_sign = OpenSSL::ASN1::Set.new(@structure.value[3].value).to_der
      assert_equal(CERTIFICATES.signer_key.sign('SHA256', to_sign), @structure.value[5].value)
    end

    describe "DSA key pair" do
      before do
        @signed_data.certificate = CERTIFICATES.dsa_signer_certificate
        @signed_data.key = CERTIFICATES.dsa_signer_key
      end

      it "works with a DSA key pair" do
        @structure = @signed_data.create("data").value[1].value[4].value[0]
        assert_equal('2.16.840.1.101.3.4.3.2', @structure.value[4].value[0].value)
        assert_nil(@structure.value[4].value[1].value)
      end

      it "fails if the digest algorithm is not SHA256" do
        @signed_data.digest_algorithm = 'sha512'
        assert_raises { @signed_data.create("data") }
      end
    end

    describe "ECDSA key pair" do
      before do
        @signed_data.certificate = CERTIFICATES.ecdsa_signer_certificate
        @signed_data.key = CERTIFICATES.ecdsa_signer_key
      end

      it "works with an ECDSA key pair" do
        structure = @signed_data.create("data").value[1].value[4].value[0]
        assert_equal('1.2.840.10045.4.3.2', structure.value[4].value[0].value)
        assert_nil(structure.value[4].value[1].value)
      end
    end

    it "can use a different digest algorithm" do
      @signed_data.digest_algorithm = 'sha384'
      structure = @signed_data.create("data").value[1].value[4].value[0]
      to_sign = OpenSSL::ASN1::Set.new(structure.value[3].value).to_der
      assert_equal('2.16.840.1.101.3.4.2.2', structure.value[2].value[0].value)
      assert_equal(CERTIFICATES.signer_key.sign('SHA384', to_sign), structure.value[5].value)
    end

    it "allows delegating the signature to a provided signing block" do
      @signed_data.key = nil
      digest_algorithm = nil
      calculated_hash = nil
      structure = @signed_data.create("data") do |algorithm, hash|
        digest_algorithm = algorithm
        calculated_hash = hash
        "signed"
      end.value[1].value[4].value[0]
      to_sign = OpenSSL::Digest.digest('SHA256', OpenSSL::ASN1::Set.new(structure.value[3].value).to_der)
      assert_equal('sha256', digest_algorithm)
      assert_equal(calculated_hash, to_sign)
      assert_equal('signed', structure.value[5].value)
    end

    describe "unsigned attributes" do
      it "allows adding a timestamp token" do
        tsh = Object.new
        io = nil
        byte_range = nil
        tsh.define_singleton_method(:sign) do |i_io, i_byte_range|
          io = i_io
          byte_range = i_byte_range
          "timestamp"
        end
        @signed_data.timestamp_handler = tsh

        structure = @signed_data.create("data").value[1].value[4].value[0]
        assert_equal(structure.value[5].value, io.string)
        assert_equal([0, io.string.size, 0, 0], byte_range)

        attr = structure.value[6].value.find {|obj| obj.value[0].value == '1.2.840.113549.1.9.16.2.14' }
        assert_equal("timestamp", attr.value[1].value[0])
      end
    end
  end

  describe "cms signature" do
    it "includes the current time as signing time" do
      Time.stub(:now, Time.at(0)) do
        asn1 = OpenSSL::ASN1.decode(@signed_data.create("data"))
        attr = asn1.value[1].value[0].value[4].value[0].value[3].value.
          find {|obj| obj.value[0].value == 'signingTime' }
        assert_equal(Time.now.utc, attr.value[1].value[0].value)
      end
    end

    it "can use a user-defined time as signing time" do
      current_time = Time.now
      @signed_data.signing_time = current_time
      asn1 = OpenSSL::ASN1.decode(@signed_data.create("data"))
      attr = asn1.value[1].value[0].value[4].value[0].value[3].value.
        find {|obj| obj.value[0].value == 'signingTime' }
      assert_equal(current_time.floor.utc, attr.value[1].value[0].value)
    end
  end

  describe "pades signature" do
    it "doesn't include the signing-time attribute" do
      signer_info = @signed_data.create("data", type: :pades).value[1].value[4].value[0]
      refute(signer_info.value[3].value.find {|obj| obj.value[0].value == 'signingTime' })
    end
  end
end
