# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/digital_signature'
require_relative 'common'

describe HexaPDF::DigitalSignature::Signing do
  before do
    @handler = HexaPDF::DigitalSignature::Signing::DefaultHandler.new(
      certificate: CERTIFICATES.signer_certificate,
      key: CERTIFICATES.signer_key,
      certificate_chain: [CERTIFICATES.ca_certificate]
    )
  end

  it "allows embedding an external signature value" do
    # Create first signature normally for testing the signature-finding code later
    doc = HexaPDF::Document.new(io: StringIO.new(MINIMAL_PDF))
    io = StringIO.new(''.b)
    doc.signatures.add(io, @handler)
    doc = HexaPDF::Document.new(io: io)
    io = StringIO.new(''.b)

    byte_range = nil
    @handler.signature_size = 5000
    @handler.certificate = nil
    @handler.external_signing = proc {|_, br| byte_range = br; "" }
    doc.signatures.add(io, @handler)

    io.pos = byte_range[0]
    data = io.read(byte_range[1])
    io.pos = byte_range[2]
    data << io.read(byte_range[3])
    contents = OpenSSL::PKCS7.sign(CERTIFICATES.signer_certificate, @handler.key, data,
                                   @handler.certificate_chain,
                                   OpenSSL::PKCS7::DETACHED | OpenSSL::PKCS7::BINARY).to_der
    HexaPDF::DigitalSignature::Signing.embed_signature(io, contents)
    doc = HexaPDF::Document.new(io: io)
    assert_equal(2, doc.signatures.each.count)
    doc.signatures.each do |signature|
      assert(signature.verify(allow_self_signed: true).messages.find {|m| m.content == 'Signature valid' })
    end
  end

  it "fails if the reserved signature space is too small" do
    doc = HexaPDF::Document.new(io: StringIO.new(MINIMAL_PDF))
    io = StringIO.new(''.b)
    def @handler.signature_size; 200; end
    msg = assert_raises(HexaPDF::Error) { doc.signatures.add(io, @handler) }
    assert_match(/space.*too small.*200 vs/, msg.message)
  end
end
