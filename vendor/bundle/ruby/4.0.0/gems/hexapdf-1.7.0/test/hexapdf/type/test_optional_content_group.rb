# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/type/optional_content_group'
require 'hexapdf/document'

describe HexaPDF::Type::OptionalContentGroup do
  before do
    @doc = HexaPDF::Document.new
    @ocg = @doc.add({Type: :OCG, Name: 'OCG'})
  end

  it "resolves all referenced type classes" do
    hash = {
      Usage: {
        CreatorInfo: {},
        Language: {},
        Export: {},
        Zoom: {},
        Print: {},
        View: {},
        User: {},
        PageElement: {},
      },
    }
    ocg = @doc.add(hash, type: :OCG)
    assert_kind_of(HexaPDF::Type::OptionalContentGroup, ocg)
    ocu = ocg[:Usage]
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage, ocu)
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::CreatorInfo,
                   ocu[:CreatorInfo])
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::Language,
                   ocu[:Language])
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::Export,
                   ocu[:Export])
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::Zoom,
                   ocu[:Zoom])
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::Print,
                   ocu[:Print])
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::View,
                   ocu[:View])
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::User,
                   ocu[:User])
    assert_kind_of(HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::PageElement,
                   ocu[:PageElement])
  end

  it "must always be an indirect object" do
    assert(@ocg.must_be_indirect?)
  end

  it "returns the name" do
    assert_equal('OCG', @ocg.name)
    @ocg.name('Other')
    assert_equal('Other', @ocg.name)
  end

  describe "intent" do
    it "can be ask whether the intent is :View" do
      assert(@ocg.intent_view?)
      @ocg[:Intent] = :Design
      refute(@ocg.intent_view?)
    end

    it "can be ask whether the intent is :Design" do
      refute(@ocg.intent_design?)
      @ocg[:Intent] = :Design
      assert(@ocg.intent_design?)
    end

    it "can apply one or more intents" do
      @ocg.apply_intent(:View)
      @ocg.apply_intent(:Design)
      assert(@ocg.intent_view?)
      assert(@ocg.intent_design?)
    end
  end

  describe "managing the OCG's default configuration" do
    it "can be asked whether it is on by default" do
      assert(@ocg.on?)
      @doc.optional_content.default_configuration[:OFF] = [@ocg]
      refute(@ocg.on?)
    end

    it "can set its default state to on" do
      @doc.optional_content.default_configuration[:OFF] = [@ocg]
      @ocg.on!
      assert(@ocg.on?)
    end

    it "can set its default state to off" do
      @ocg.off!
      refute(@ocg.on?)
    end

    it "can add itself to the UI" do
      @ocg.add_to_ui(path: 'Test')
      assert_equal([['Test', @ocg]], @doc.optional_content.default_configuration[:Order].value)
    end
  end

  it "can set and return the creator info usage entry" do
    refute(@ocg.creator_info)
    dict = @ocg.creator_info("HexaPDF", :Technical)
    assert_equal({Creator: "HexaPDF", Subtype: :Technical}, dict.value)
    assert_raises(ArgumentError) { @ocg.creator_info("HexaPDF") }
  end

  it "can set and return the language usage entry" do
    refute(@ocg.language)
    dict = @ocg.language('de')
    assert_equal({Lang: "de", Preferred: :OFF}, dict.value)
    @ocg.language('de', preferred: true)
    assert_equal({Lang: "de", Preferred: :ON}, @ocg.language.value)
  end

  it "can set and return the export state usage entry" do
    refute(@ocg.export_state)
    assert(@ocg.export_state(true))
    assert(@ocg.export_state)
  end

  it "can set and return the view state usage entry" do
    refute(@ocg.view_state)
    assert(@ocg.view_state(true))
    assert(@ocg.view_state)
  end

  it "can set and return the print state usage entry" do
    refute(@ocg.print_state)
    dict = @ocg.print_state(true)
    assert_equal({PrintState: :ON, Subtype: nil}, dict.value)
    @ocg.print_state(true, subtype: :Watermark)
    assert_equal({PrintState: :ON, Subtype: :Watermark}, @ocg.print_state.value)
  end

  it "can set and return the zoom usage entry" do
    refute(@ocg.zoom)
    dict = @ocg.zoom(min: 2.0)
    assert_equal({min: 2.0, max: nil}, dict.value)
    assert_equal({min: nil, max: 3.0}, @ocg.zoom(max: 3.0).value)
    assert_equal({min: 1.0, max: 3.0}, @ocg.zoom(min: 1.0, max: 3.0).value)
  end

  it "can set and return the intended user usage entry" do
    refute(@ocg.intended_user)
    dict = @ocg.intended_user(:Ind, 'Me')
    assert_equal({Type: :Ind, Name: "Me"}, dict.value)
  end

  it "can set and return the page element usage entry" do
    refute(@ocg.page_element)
    assert_equal(:HF, @ocg.page_element(:HF))
    @ocg.page_element(:L)
    assert_equal(:L, @ocg.page_element)
  end
end
