# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/signature_field'

describe HexaPDF::Type::AcroForm::SignatureField::LockDictionary do
  it "validates the presence of the /Fields key" do
    doc = HexaPDF::Document.new
    obj = HexaPDF::Type::AcroForm::SignatureField::LockDictionary.new({Action: :All}, document: doc)
    assert(obj.validate)
    obj[:Action] = :Include
    refute(obj.validate)
  end
end

describe HexaPDF::Type::AcroForm::SignatureField do
  before do
    @doc = HexaPDF::Document.new
    @field = @doc.wrap({}, type: :XXAcroFormField, subtype: :Sig)
  end

  it "identifies as an :XXAcroFormField type" do
    assert_equal(:XXAcroFormField, @field.type)
  end

  it "sets the field value" do
    @field.field_value = {Empty: :True}
    assert_equal({Empty: :True}, @field[:V].value)
  end

  it "gets the field value" do
    @field[:V] = {Empty: :True}
    value = @field.field_value
    assert_kind_of(HexaPDF::DigitalSignature::Signature, value)
    assert_equal({Empty: :True}, value)
  end

  it "validates the value of the /FT field" do
    refute(@field.validate(auto_correct: false))
    assert(@field.validate)
    assert_equal(:Sig, @field.field_type)
  end
end
