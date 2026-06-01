# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/digital_signature'

describe HexaPDF::DigitalSignature::VerificationResult do
  describe "Message" do
    it "accepts a type and a content argument on creation" do
      m = HexaPDF::DigitalSignature::VerificationResult::Message.new(:type, 'content')
      assert_equal(:type, m.type)
      assert_equal('content', m.content)
    end

    it "allows sorting by type" do
      info =  HexaPDF::DigitalSignature::VerificationResult::Message.new(:info, 'c')
      warning = HexaPDF::DigitalSignature::VerificationResult::Message.new(:warning, 'c')
      error = HexaPDF::DigitalSignature::VerificationResult::Message.new(:error, 'c')
      assert_equal([error, warning, info], [info, error, warning].sort)
    end
  end

  before do
    @result = HexaPDF::DigitalSignature::VerificationResult.new
  end

  it "can add new messages" do
    @result.log(:error, "content")
    assert_equal(1, @result.messages.size)
    assert_equal(:error, @result.messages[0].type)
    assert_equal('content', @result.messages[0].content)
  end

  it "reports success if no error messages have been logged" do
    assert(@result.success?)
    @result.log(:info, 'content')
    assert(@result.success?)
    @result.log(:error, 'failure')
    refute(@result.success?)
  end

  it "reports failure if there is at least one error message" do
    @result.log(:info, 'content')
    refute(@result.failure?)
    @result.log(:error, 'failure')
    assert(@result.failure?)
  end
end
