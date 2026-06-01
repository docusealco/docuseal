# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'tempfile'
require 'hexapdf/document'
require_relative 'common'

describe HexaPDF::DigitalSignature::Signatures do
  before do
    @doc = HexaPDF::Document.new
    @form = @doc.acro_form(create: true)
    @sig1 = @form.create_signature_field("test1")
    @sig2 = @form.create_signature_field("test2")
  end

  it "iterates over all signature dictionaries" do
    assert_equal([], @doc.signatures.to_a)
    @sig1.field_value = {k: :sig1}
    @sig2.field_value = {k: :sig2}
    assert_equal([{k: :sig1}, {k: :sig2}], @doc.signatures.to_a)
  end

  it "returns the number of signature dictionaries" do
    @sig1.field_value = {k: :sig1}
    assert_equal(1, @doc.signatures.count)
  end

  describe "signing_handler" do
    it "return the initialized handler" do
      handler = @doc.signatures.signing_handler(certificate: 'cert', reason: 'reason')
      assert_equal('cert', handler.certificate)
      assert_equal('reason', handler.reason)
    end

    it "fails if the given task is not available" do
      assert_raises(HexaPDF::Error) { @doc.signatures.signing_handler(name: :unknown) }
    end
  end

  describe "add" do
    before do
      @doc = HexaPDF::Document.new(io: StringIO.new(MINIMAL_PDF))
      @io = StringIO.new(''.b)
      @handler = @doc.signatures.signing_handler(
        certificate: CERTIFICATES.signer_certificate,
        key: CERTIFICATES.signer_key,
        certificate_chain: [CERTIFICATES.ca_certificate]
      )
    end

    it "uses the provided signature dictionary" do
      sig = @doc.add({Type: :Sig, Key: :value})
      @doc.signatures.add(@io, @handler, signature: sig)
      assert_equal(1, @doc.signatures.to_a.compact.size)
      assert_equal(:value, @doc.signatures.to_a[0][:Key])
      refute_equal(:value, @doc.acro_form.each_field.first[:Key])
    end

    it "creates the signature dictionary if none is provided" do
      @doc.signatures.add(@io, @handler)
      assert_equal(1, @doc.signatures.to_a.compact.size)
      refute(@doc.acro_form.each_field.first.key?(:Contents))
    end

    it "sets the needed information on the signature dictionary" do
      def @handler.finalize_objects(sigfield, sig)
        sig[:key] = :sig
        sigfield[:key] = :sig_field
      end
      @doc.signatures.add(@io, @handler, write_options: {update_fields: false})
      sig = @doc.signatures.first
      assert_equal([0, 925, 925 + (sig[:Contents].size + 5) * 2 + 2, 2455 + HexaPDF::VERSION.length],
                   sig[:ByteRange].value)
      assert_equal(:sig, sig[:key])
      assert_equal(:sig_field, @doc.acro_form.each_field.first[:key])
      assert(sig.key?(:Contents))
    end

    it "creates the main form dictionary if necessary" do
      @doc.signatures.add(@io, @handler)
      assert(@doc.acro_form)
      assert_equal([:signatures_exist, :append_only], @doc.acro_form.signature_flags)
    end

    it "uses the provided signature field" do
      field = @doc.acro_form(create: true).create_signature_field('Signature2')
      @doc.signatures.add(@io, @handler, signature: field)
      assert_nil(@doc.acro_form.field_by_name("Signature3"))
      refute_nil(field.field_value)
      assert_nil(@doc.signatures.first[:T])
    end

    it "uses an existing signature field if possible" do
      field = @doc.acro_form(create: true).create_signature_field('Signature2')
      field.field_value = sig = @doc.add({Type: :Sig, key: :value})
      @doc.signatures.add(@io, @handler, signature: sig)
      assert_nil(@doc.acro_form.field_by_name("Signature3"))
      assert_same(sig, @doc.signatures.first)
    end

    it "creates the signature field if necessary" do
      @doc.acro_form(create: true).create_text_field('Signature2')
      @doc.signatures.add(@io, @handler)
      field = @doc.acro_form.field_by_name("Signature3")
      assert_equal(:Sig, field.field_type)
      refute_nil(field.field_value)
      assert_equal(1, field.each_widget.count)
    end

    it "creates an empty widget on the first page for the signature field if necessary" do
      @doc.pages.add
      field = @doc.acro_form(create: true).create_signature_field('Signature2')
      field.field_value = sig = @doc.add({Type: :Sig, key: :value})
      @doc.signatures.add(@io, @handler, signature: sig)
      widgets = field.each_widget.to_a
      assert_equal(1, widgets.size)
      assert_equal(@doc.pages[0], widgets[0][:P])
      assert_equal([0, 0, 0, 0], widgets[0][:Rect])
    end

    it "handles a bug in Adobe Acrobat related to images not showing without a /Resources entry" do
      field = @doc.acro_form(create: true).create_signature_field('Signature')
      image = @doc.add({Type: :XObject, Subtype: :Image, Width: 1, Height: 1, ColorSpace: :DeviceGray,
                        BitsPerComponent: 8}, stream: 'A')
      field.create_widget(@doc.pages[0], Rect: [0, 0, 100, 100]).create_appearance.
        canvas.xobject(image, at: [0, 0])
      @doc.signatures.add(@io, @handler, signature: field)
      assert(image.key?(:Resources))
      assert_equal({}, image[:Resources])
    end

    it "handles different xref section types correctly when determing the offsets" do
      @doc.delete(7)
      sig = @doc.signatures.add(@io, @handler, write_options: {update_fields: false})
      l1 = 1030 + HexaPDF::VERSION.length
      assert_equal([0, l1, l1 + (sig[:Contents].size + 5) * 2 + 2, 2437 + HexaPDF::VERSION.length],
                   sig[:ByteRange].value)
    end

    it "works if the signature object is the last object of the xref section" do
      field = @doc.acro_form(create: true).create_signature_field('Signature2')
      field.create_widget(@doc.pages[0], Rect: [0, 0, 0, 0])
      sig = @doc.signatures.add(@io, @handler, signature: field, write_options: {update_fields: false})
      l1 = 3097 + HexaPDF::VERSION.length
      assert_equal([0, l1, l1 + (sig[:Contents].size + 5) * 2 + 2, 374 + HexaPDF::VERSION.length],
                   sig[:ByteRange].value)
    end

    it "allows writing to a file in addition to writing to an IO" do
      tempfile = Tempfile.new('hexapdf-signature')
      tempfile.close
      @doc.signatures.add(tempfile.path, @handler)
      doc = HexaPDF::Document.open(tempfile.path)
      assert(doc.signatures.first.verify(allow_self_signed: true).success?)
    end

    it "adds a new revision with the signature" do
      @doc.signatures.add(@io, @handler)
      signed_doc = HexaPDF::Document.new(io: @io)
      assert(signed_doc.signatures.first.verify)
    end
  end
end
