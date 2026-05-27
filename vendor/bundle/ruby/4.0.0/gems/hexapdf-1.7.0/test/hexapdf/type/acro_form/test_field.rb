# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/field'

describe HexaPDF::Type::AcroForm::Field::HashRefinement do
  using HexaPDF::Type::AcroForm::Field::HashRefinement

  it "returns self when calling value" do
    x = {}
    assert_same(x, x.value)
  end
end

describe HexaPDF::Type::AcroForm::Field do
  before do
    @doc = HexaPDF::Document.new
    @field = @doc.add({}, type: :XXAcroFormField)
    @doc.acro_form(create: true).root_fields << @field
  end

  it "must always be an indirect object" do
    assert(@field.must_be_indirect?)
  end

  it "resolves inherited field values" do
    assert_nil(@field[:FT])

    @field[:Parent] = {FT: :Tx}
    assert_equal(:Tx, @field[:FT])

    @field[:FT] = :Ch
    assert_equal(:Ch, @field[:FT])
  end

  it "wraps fields inside the correct subclass" do
    field = HexaPDF::Type::AcroForm::Field.wrap(@doc, {FT: :Tx})
    assert_kind_of(HexaPDF::Type::AcroForm::TextField, field)
    field = HexaPDF::Type::AcroForm::Field.wrap(@doc, {})
    assert_kind_of(HexaPDF::Type::AcroForm::Field, field)
  end

  it "has convenience methods for accessing the field flags" do
    assert_equal([], @field.flags)
    refute(@field.flagged?(:required))
    @field.flag(:required, 2)
    assert(@field.flagged?(2))
    assert_equal(6, @field[:Ff])
  end

  it "returns the field type" do
    assert_nil(@field.field_type)

    @field[:FT] = :Tx
    assert_equal(:Tx, @field.field_type)
  end

  it "returns the concrete field type" do
    assert_nil(@field.concrete_field_type)

    @field[:FT] = :Tx
    assert_equal(:text_field, @field.concrete_field_type)
    @field[:FT] = :Btn
    assert_equal(:button_field, @field.concrete_field_type)
    @field[:FT] = :Ch
    assert_equal(:choice_field, @field.concrete_field_type)
    @field[:FT] = :Sig
    assert_equal(:signature_field, @field.concrete_field_type)
  end

  it "returns the field name" do
    assert_nil(@field.field_name)
    @field[:T] = 'test'
    assert_equal('test', @field.field_name)
  end

  it "returns the full name of the field" do
    assert_nil(@field.full_field_name)

    @field[:T] = "Test"
    assert_equal("Test", @field.full_field_name)

    @field[:Parent] = {}
    assert_equal("Test", @field.full_field_name)

    @field[:Parent] = {T: 'Parent'}
    assert_equal("Parent.Test", @field.full_field_name)
  end

  it "allows setting and retrieving the alternate field name" do
    @field.alternate_field_name = 'Alternate'
    assert_equal('Alternate', @field.alternate_field_name)
    assert_equal('Alternate', @field[:TU])
  end

  it "returns whether the field is a terminal field" do
    assert(@field.terminal_field?)

    @field[:Kids] = []
    assert(@field.terminal_field?)

    @field[:Kids] = [{Subtype: :Widget}]
    assert(@field.terminal_field?)

    @field[:Kids] = [{FT: :Tx, T: 'name'}]
    refute(@field.terminal_field?)
  end

  it "returns itself when asked for the form field" do
    assert_same(@field, @field.form_field)
  end

  it "can check whether a widget is embedded in the field" do
    refute(@field.embedded_widget?)
    @field[:Subtype] = :Wdiget
    assert(@field.embedded_widget?)
  end

  describe "each_widget" do
    it "yields a wrapped instance of self if a single widget is embedded" do
      @field[:Subtype] = :Widget
      @field[:Rect] = [0, 0, 0, 0]
      widgets = @field.each_widget.to_a
      assert_kind_of(HexaPDF::Type::Annotations::Widget, widgets.first)
      assert_same(@field.data, widgets.first.data)
    end

    it "yields all widgets in the /Kids array" do
      @field[:Kids] = [{Subtype: :Widget, Rect: [0, 0, 0, 0], X: 1}]
      widgets = @field.each_widget.to_a
      assert_kind_of(HexaPDF::Type::Annotations::Widget, widgets.first)
      assert_equal(1, widgets.first[:X])
    end

    it "yields all widgets of other fields with the same full field name" do
      @field[:T] = 'a'
      @doc.acro_form.root_fields <<
        @doc.add({T: "b", Subtype: :Widget, Rect: [0, 0, 0, 0]}, type: :XXAcroFormField) <<
        @doc.add({T: "a", X: 1, Subtype: :Widget, Rect: [0, 0, 0, 0]}, type: :XXAcroFormField)

      widgets = @field.each_widget(direct_only: false).to_a
      assert_kind_of(HexaPDF::Type::Annotations::Widget, widgets.first)
      assert_equal(1, widgets.first[:X])
    end

    it "yields nothing if no widgets are defined" do
      assert_equal([], @field.each_widget.to_a)
    end

    it "ignores entries in the /Kids array that are not widgets" do
      @field[:Kids] = [{Subtype: :Widget, Rect: [0, 0, 0, 0], X: 1}, {FT: :Tx, Kids: []}]
      assert_equal(1, @field.each_widget.to_a.size)
    end
  end

  describe "create_widget" do
    before do
      @page = @doc.pages.add
    end

    it "sets all required widget keys" do
      widget = @field.create_widget(@page)
      assert_equal(:Annot, widget.type)
      assert_equal(:Widget, widget[:Subtype])
      assert_equal([0, 0, 0, 0], widget[:Rect])
    end

    it "sets the additionally specified keys on the widget" do
      widget = @field.create_widget(@page, X: 5)
      assert_equal(5, widget[:X])
    end

    it "sets the print flag on the widget" do
      widget = @field.create_widget(@page, X: 5)
      assert_equal([:print], widget.flags)
    end

    it "associates the page with the widget" do
      widget = @field.create_widget(@page, X: 5)
      assert_same(@page, widget[:P])
    end

    it "adds the new widget to the given page's annotations" do
      widget = @field.create_widget(@page)
      assert_equal([widget], @page[:Annots].value)
    end

    it "populates the field with the widget data if there is no widget" do
      widget = @field.create_widget(@page)
      assert_same(widget.data, @field.data)
      assert_nil(@field[:Kids])
    end

    it "creates a standalone widget if embedding is not allowed" do
      refute_same(@field.data, @field.create_widget(@page, allow_embedded: false).data)
    end

    it "extracts an embedded widget into a standalone object if necessary" do
      widget1 = @field.create_widget(@page, Rect: [1, 2, 3, 4])
      # Make sure that the field/widget looks like as if it has been loaded from a file
      @doc.revisions.current.update(widget1)
      assert_equal(@field, widget1)

      widget2 = @field.create_widget(@doc.pages.add, Rect: [2, 1, 4, 3])
      kids = @field[:Kids]

      assert_kind_of(HexaPDF::Type::AcroForm::Field, @doc.object(@field.oid))
      assert_equal(2, kids.length)
      refute_same(widget1, kids[0])
      assert_same(widget2, kids[1])
      assert_nil(@field[:Rect])
      assert_equal({Rect: [1, 2, 3, 4], Type: :Annot, Subtype: :Widget, Parent: @field, F: 4, P: @page},
                   kids[0].value)
      assert_equal([2, 1, 4, 3], kids[1][:Rect].value)

      refute_equal([widget1], @page[:Annots].value)
      assert_equal([kids[0]], @page[:Annots].value)
    end

    it "fails if called on a non-terminal field" do
      @field[:Kids] = [{T: 'name'}]
      assert_raises(HexaPDF::Error) { @field.create_widget(@page) }
    end
  end

  describe "delete_widget" do
    before do
      @page = @doc.pages.add
    end

    it "does nothing if the provided widget doesn't belong to the field" do
      wrong_widget = @doc.add({Subtype: :Widget})

      @field.create_widget(@page)
      @field.delete_widget(wrong_widget)
      assert_equal(:Widget, @field[:Subtype])

      @field.create_widget(@page)
      @field.delete_widget(wrong_widget)
      assert_equal(2, @field[:Kids].size)
    end

    it "deletes the widget if it is embedded" do
      widget = @field.create_widget(@page)
      @doc.revisions.current.update(widget)
      assert_same(widget, @doc.object(widget))
      refute_same(@field, @doc.object(@field))

      @field.delete_widget(widget)
      refute(@field.key?(:Subtype))
      assert(@page[:Annots].empty?)
      assert_same(@field, @doc.object(@field))
    end

    it "deletes the widget if it is not embedded" do
      @field.create_widget(@page)
      widget2 = @field.create_widget(@page)
      @field.delete_widget(widget2)
      assert_equal(1, @field[:Kids].size)
      assert_equal(@field[:Kids].value, @page[:Annots].value)
    end
  end

  describe "perform_validation" do
    before do
      @field[:FT] = :Tx
    end

    it "requires the /FT key to be present for terminal fields" do
      assert(@field.validate)

      @field.delete(:FT)
      refute(@field.validate)

      @field[:Kids] = [{T: 'name'}]
      assert(@field.validate)
    end

    it "doesn't allow periods in partial field names" do
      assert(@field.validate)

      @field[:T] = "Test"
      assert(@field.validate)

      @field[:T] = "Te.st"
      refute(@field.validate)
    end
  end
end
