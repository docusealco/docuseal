# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/annotation'

describe HexaPDF::Type::Annotation::AppearanceDictionary do
  before do
    @doc = HexaPDF::Document.new
    @ap = @doc.add({N: :n, D: :d, R: :r}, type: :XXAppearanceDictionary)
  end

  it "resolves the normal appearance" do
    assert_equal(:n, @ap.normal_appearance)
  end

  it "resolves the rollover appearance" do
    assert_equal(:r, @ap.rollover_appearance)
    @ap.delete(:R)
    assert_equal(:n, @ap.rollover_appearance)
  end

  it "resolves the down appearance" do
    assert_equal(:d, @ap.down_appearance)
    @ap.delete(:D)
    assert_equal(:n, @ap.down_appearance)
  end

  describe "set_appearance" do
    it "sets the appearance for the given type" do
      @ap.set_appearance(1, type: :normal)
      @ap.set_appearance(2, type: :rollover)
      @ap.set_appearance(3, type: :down)

      assert_equal(1, @ap.normal_appearance)
      assert_equal(2, @ap.rollover_appearance)
      assert_equal(3, @ap.down_appearance)
    end

    it "respects the provided state name" do
      @ap.set_appearance(1, state_name: :X)
      assert_equal(1, @ap.normal_appearance[:X])
    end

    it "fails if an invalid appearance type is specified" do
      assert_raises(ArgumentError) { @ap.set_appearance(5, type: :other) }
    end
  end
end

describe HexaPDF::Type::Annotation do
  before do
    @doc = HexaPDF::Document.new
    @annot = @doc.add({Type: :Annot, Subtype: :Link, F: 0b100011, Rect: [10, 10, 110, 60]})
  end

  it "must always be indirect" do
    @annot.must_be_indirect = false
    assert(@annot.must_be_indirect?)
  end

  it "returns the appearance dictionary" do
    @annot[:AP] = :yes
    assert_equal(:yes, @annot.appearance_dict)
  end

  it "returns the appearance stream of the given type" do
    assert_nil(@annot.appearance)

    @annot[:AP] = 'some invalid type'
    assert_nil(@annot.appearance)

    @annot[:AP] = {N: {}}
    assert_nil(@annot.appearance)

    stream = @doc.wrap({}, stream: '')
    @annot[:AP][:N] = stream
    assert_nil(@annot.appearance)

    stream[:BBox] = [1, 2, 3, 4]
    appearance = @annot.appearance
    assert_same(stream.data, appearance.data)
    assert_kind_of(HexaPDF::Type::Form, appearance)

    stream[:Type] = :XObject
    stream[:Subtype] = :Form
    appearance = @annot.appearance
    assert_same(stream.data, appearance.data)
    assert_kind_of(HexaPDF::Type::Form, appearance)

    @annot[:AP][:N] = {X: {}}
    assert_nil(@annot.appearance)

    @annot[:AS] = :X
    @annot[:AP][:N][:X] = stream
    assert_same(stream.data, @annot.appearance.data)

    @annot[:AP][:D] = {X: stream}
    assert_same(stream.data, @annot.appearance(type: :down).data)
    assert_same(stream.data, @annot.appearance(type: :down, state_name: :X).data)
  end

  describe "create_appearance" do
    it "creates the appearance stream directly underneath /AP" do
      stream = @annot.create_appearance
      assert_same(stream, @annot.appearance_dict.normal_appearance)
    end

    it "respects the state name when creating the appearance" do
      stream = @annot.create_appearance(type: :down, state_name: :X)
      assert_same(stream, @annot.appearance_dict.down_appearance[:X])

      @annot[:AS] = :X
      stream = @annot.create_appearance(type: :down)
      assert_same(stream, @annot.appearance_dict.down_appearance[:X])
    end
  end

  describe "regenerate_appearance" do
    it "regenerates the appearance using the data from the annotation object" do
      @annot[:Subtype] = :Unknown
      error = assert_raises(HexaPDF::Error) { @annot.regenerate_appearance }
      assert_match(/Unknown.*not.*supported/, error.message)
    end
  end

  describe "flags" do
    it "returns all flags" do
      assert_equal([:invisible, :hidden, :no_view], @annot.flags)
    end
  end

  describe "flagged?" do
    it "returns true if the given flag is set" do
      assert(@annot.flagged?(:hidden))
      refute(@annot.flagged?(:locked))
    end

    it "raises an error if an unknown flag name is provided" do
      assert_raises(ArgumentError) { @annot.flagged?(:unknown) }
    end
  end

  describe "flag" do
    it "sets the given flag bits" do
      @annot.flag(:locked)
      assert_equal([:invisible, :hidden, :no_view, :locked], @annot.flags)
      @annot.flag(:locked, clear_existing: true)
      assert_equal([:locked], @annot.flags)
    end
  end

  describe "contents" do
    it "returns the contents value" do
      assert_nil(@annot.contents)
      @annot[:Contents] = "test"
      assert_equal("test", @annot.contents)
    end

    it "sets the contents value" do
      assert_same(@annot, @annot.contents("Test"))
      assert_equal("Test", @annot[:Contents])
      @annot.contents(nil)
      assert_nil(@annot[:Contents])
    end
  end

  describe "opacity" do
    it "returns the opacity values" do
      opacity = @annot.opacity
      assert_equal(1, opacity.fill_alpha)
      assert_equal(1, opacity.stroke_alpha)

      @annot[:CA] = 0.5
      opacity = @annot.opacity
      assert_equal(0.5, opacity.fill_alpha)
      assert_equal(0.5, opacity.stroke_alpha)

      @annot[:ca] = 0.3
      opacity = @annot.opacity
      assert_equal(0.3, opacity.fill_alpha)
      assert_equal(0.5, opacity.stroke_alpha)
    end

    it "sets the opacity values" do
      @annot.opacity(fill_alpha: 0.3)
      refute(@annot.key?(:CA))
      assert_equal(0.3, @annot[:ca])

      @annot.opacity(stroke_alpha: 0.5)
      assert_equal(0.3, @annot[:ca])
      assert_equal(0.5, @annot[:CA])

      @annot.opacity(stroke_alpha: 0.1, fill_alpha: 0.2)
      assert_equal(0.1, @annot[:CA])
      assert_equal(0.2, @annot[:ca])
    end
  end

  describe "validation" do
    it "makes sure that empty appearance stream dictionaries don't cause validation errors" do
      assert(@annot.validate)
      @annot[:AP] = HexaPDF::Reference.new(@doc.add({}).oid)
      msg = nil
      assert(@annot.validate {|imsg| msg = imsg })
      assert_match(/appearance.*must not be empty/, msg)
    end
  end
end
