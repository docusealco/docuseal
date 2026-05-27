# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/type/optional_content_properties'
require 'hexapdf/document'

describe HexaPDF::Type::OptionalContentProperties do
  before do
    @doc = HexaPDF::Document.new
    @oc = @doc.optional_content
  end

  describe "add_ocg" do
    it "adds a given OCG object" do
      ocg = @doc.add({Type: :OCG, Name: 'test'})
      assert_same(ocg, @oc.add_ocg(ocg))
      assert_equal([ocg], @oc[:OCGs])
    end

    it "doesn't add an OCG if it has been added before" do
      ocg = @doc.add({Type: :OCG, Name: 'test'})
      @oc.add_ocg(ocg)
      @oc.add_ocg(ocg)
      assert_equal([ocg], @oc[:OCGs])
    end

    it "creates a new OCG object with the given name and adds it" do
      ocg = @oc.add_ocg('Test')
      assert_equal([ocg], @oc[:OCGs])
    end
  end

  describe "ocg" do
    it "returns the first OCG with the given name, regardless of the create argument" do
      ocg1  = @oc.add_ocg('Test')
      _ocg2 = @oc.add_ocg('Test')
      assert_same(ocg1, @oc.ocg('Test', create: false))
      assert_same(ocg1, @oc.ocg('Test', create: true))
    end

    it "returns nil if no OCG with the given name exists and create is false" do
      assert_nil(@oc.ocg('Other', create: false))
      @oc.add_ocg('Test')
      assert_nil(@oc.ocg('Other', create: false))
    end

    it "creates an OCG with the given name if none is found and create is true" do
      ocg = @oc.ocg('Test')
      assert_same(ocg, @oc.ocg('Test'))
      assert_equal([ocg], @oc[:OCGs])
    end
  end

  describe "ocgs" do
    it "returns the list of the known optional content groups, with duplicates removed" do
      ocg1 = @oc.add_ocg(@oc.add_ocg('Test'))
      @oc[:OCGs] << nil
      ocg2 = @oc.add_ocg('Test')
      ocg3 = @oc.add_ocg('Other')
      assert_equal([ocg1, ocg2, ocg3], @oc.ocgs)
    end
  end

  describe "create_ocmd" do
    it "creates the optional content membership dictionary for the given OCGs" do
      ocmd = @oc.create_ocmd(@oc.ocg('Test'))
      assert_equal({Type: :OCMD, OCGs: [@oc.ocg('Test')], P: :AnyOn}, ocmd.value)

      ocmd = @oc.create_ocmd([@oc.ocg('Test'), @oc.ocg('Test2')], policy: :any_off)
      assert_equal({Type: :OCMD, OCGs: [@oc.ocg('Test'), @oc.ocg('Test2')], P: :AnyOff}, ocmd.value)
    end

    it "fails if the policy is invalid" do
      error = assert_raises(ArgumentError) { @oc.create_ocmd(:ocg, policy: :unknown) }
      assert_match(/Invalid OCMD.*unknown/, error.message)
    end
  end

  describe "default_configuration" do
    it "returns an existing dictionary" do
      dict = @oc.default_configuration
      assert_same(@oc[:D], dict)
      assert_kind_of(HexaPDF::Type::OptionalContentConfiguration, dict)
    end

    it "sets and returns a default configuration dictionary if none is set" do
      @oc.delete(:D)
      assert_equal({Name: 'Default', Creator: 'HexaPDF'}, @oc.default_configuration.value)
    end

    it "sets the default configuration dictionary to the given value" do
      d_before = @oc[:D]
      d_new = @oc.default_configuration(Creator: 'Test')
      refute_same(d_before, d_new)
      assert_same(@oc[:D], d_new)
      assert_equal({Creator: 'Test'}, d_new.value)
    end
  end

  describe "perform_validation" do
    it "creates the /D entry if it is not set" do
      @oc.delete(:D)
      refute(@oc.validate(auto_correct: false))
      refute(@oc.key?(:D))
      assert(@oc.validate(auto_correct: true))
      assert_equal({Name: 'Default', Creator: 'HexaPDF'}, @oc[:D].value)
    end
  end
end
