# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'tempfile'
require 'hexapdf/document'
require 'hexapdf/type/form'

describe HexaPDF::Type::Form do
  before do
    @doc = HexaPDF::Document.new
    @form = @doc.wrap({}, type: :XObject, subtype: :Form)
  end

  describe "box" do
    before do
      @form[:BBox] = [10, 10, 110, 60]
    end

    it "returns the /BBox entry" do
      assert_equal([10, 10, 110, 60], @form.box.value)
    end

    it "returns the box's width" do
      assert_equal(100, @form.width)
    end

    it "returns the box's height" do
      assert_equal(50, @form.height)
    end
  end

  describe "contents" do
    it "returns a duplicate of the stream" do
      @form.stream = 'test'
      assert_equal(@form.stream, @form.contents)
      @form.contents.gsub!(/test/, 'other')
      assert_equal(@form.stream, @form.contents)
    end
  end

  describe "contents=" do
    it "set the stream contents" do
      @form.contents = 'test'
      assert_equal('test', @form.stream)
    end

    it "clears the cache to make sure that a new canvas can be created" do
      @form[:BBox] = [0, 0, 100, 100]
      canvas = @form.canvas
      @form.contents = ''
      refute_same(canvas, @form.canvas)
    end
  end

  describe "resources" do
    it "creates the resource dictionary if it is not found" do
      resources = @form.resources
      assert_equal(:XXResources, resources.type)
      assert_equal({}, resources.value)
    end

    it "returns the already used resource dictionary" do
      @form[:Resources] = {Font: nil}
      resources = @form.resources
      assert_equal(:XXResources, resources.type)
      assert_equal(@form[:Resources], resources)
    end
  end

  describe "process_contents" do
    it "parses the contents and processes it" do
      @form.stream = '10 w'
      processor = HexaPDF::TestUtils::OperatorRecorder.new
      @form.process_contents(processor)
      assert_equal([[:set_line_width, [10]]], processor.recorded_ops)
      assert_nil(@form[:Resources])

      resources = @form.resources
      @form.process_contents(processor)
      assert_same(resources, processor.resources)
    end

    it "uses the provided resources if it has no resources itself" do
      resources = @doc.wrap({}, type: :XXResources)
      processor = HexaPDF::TestUtils::OperatorRecorder.new
      @form.process_contents(processor, original_resources: resources)
      assert_same(resources, processor.resources)
    end

    it "uses the referenced content in case of a Reference XObject" do
      @form[:Ref] = @doc.add({F: {}})
      io = StringIO.new
      HexaPDF::Document.new.tap {|d| d.pages.add.canvas.line_width(5) }.write(io)
      @form[:Ref][:F].embed(io, name: 'test')
      @form[:Ref][:Page] = 0

      processor = HexaPDF::TestUtils::OperatorRecorder.new
      @form.process_contents(processor)
      assert_equal([[:set_line_width, [5]]], processor.recorded_ops)
    end
  end

  describe "canvas" do
    # Asserts that the form's contents contains the operators.
    def assert_operators(form, operators)
      processor = HexaPDF::TestUtils::OperatorRecorder.new
      form.process_contents(processor)
      assert_equal(operators, processor.recorded_ops)
    end

    it "always returns the same Canvas instance" do
      @form[:BBox] = [0, 0, 100, 100]
      canvas = @form.canvas
      assert_same(canvas, @form.canvas)
      assert_operators(@form, [])
    end

    it "always moves the origin to the bottom left corner of the bounding box" do
      @form[:BBox] = [-10, -5, 100, 300]
      @form.canvas.line_width = 5
      assert_operators(@form, [[:save_graphics_state],
                               [:concatenate_matrix, [1, 0, 0, 1, -10, -5]],
                               [:set_line_width, [5]],
                               [:restore_graphics_state]])
    end

    it "doesn't move the origin if translate is false" do
      @form[:BBox] = [-10, -5, 100, 300]
      @form.canvas(translate: false).line_width = 5
      assert_operators(@form, [[:set_line_width, [5]]])
    end

    it "fails if the form XObject already has data" do
      @form.stream = '10 w'
      assert_raises(HexaPDF::Error) { @form.canvas }
    end
  end

  describe "reference_xobject?" do
    it "returns true if the form is a reference XObject" do
      refute(@form.reference_xobject?)
      @form[:Ref] = {}
      assert(@form.reference_xobject?)
    end
  end

  describe "referenced_content" do
    before do
      @form[:BBox] = [10, 10, 110, 60]
      @form[:Matrix] = [1, 0, 0, 1, 10, 20]
      @form[:Ref] = @doc.add({F: {}})
      @ref = @form[:Ref]
    end

    it "returns a Form XObject with the imported page from an embedded file" do
      io = StringIO.new
      HexaPDF::Document.new.tap {|d| d.pages.add.canvas.line_width(5) }.write(io)
      @ref[:F].embed(io, name: 'test.pdf')
      @ref[:Page] = 0

      ref_form = @form.referenced_content
      refute_nil(ref_form)
      assert_equal([10, 10, 110, 60], ref_form[:BBox].value)
      assert_equal([1, 0, 0, 1, 10, 20], ref_form[:Matrix].value)
      assert_equal("5 w\n", ref_form.contents)
    end

    it "returns a Form XObject with the imported page from an external file" do
      file = Tempfile.new('hexapdf')
      HexaPDF::Document.new.tap {|d| d.pages.add.canvas.line_width(5) }.write(file.path)
      @ref[:F].path = file.path
      @ref[:Page] = 0
      assert_equal("5 w\n", @form.referenced_content.contents)
    end

    it "also works with a page label" do
      file = Tempfile.new('hexapdf')
      HexaPDF::Document.new.tap do |d|
        d.pages.add
        d.pages.add
        d.pages.add.canvas.line_width(5)
        d.pages.add
        d.pages.add_labelling_range(1, numbering_style: :decimal, prefix: 'Test', start_number: 4)
      end.write(file.path)
      @ref[:F].path = file.path
      @ref[:Page] = 'Test5'
      assert_equal("5 w\n", @form.referenced_content.contents)
    end

    it "flattens printable annotations into the page's content stream" do
      io = StringIO.new
      HexaPDF::Document.new.tap do |d|
        d.pages.add.canvas.line_width(5)
        tf = d.acro_form(create: true).create_text_field('text')
        widget = tf.create_widget(d.pages[0], Rect: [10, 10, 30, 30])
        widget.border_style(color: "black")
        widget = tf.create_widget(d.pages[0], Rect: [40, 10, 70, 30])
        widget.border_style(color: "red")
        tf.field_value = 't'
        widget.unflag(:print)
      end.write(io)
      @ref[:F].embed(io, name: 'Test')
      @ref[:Page] = 0
      assert_equal(" q  Q q  5 w\n  Q q q\n1.0 0 0 1.0 10.0 10.0 cm\n/XO1 Do\nQ\n Q ",
                   @form.referenced_content.contents)
    end

    it "returns nil if the form is not a reference XObject" do
      @form.delete(:Ref)
      assert_nil(@form.referenced_content)
    end

    it "returns nil if the file is not embedded and not found" do
      @ref[:F].path = '/tmp/non_existing_path'
      assert_nil(@form.referenced_content)
    end

    it "returns nil if the page referenced by page number is not found" do
      io = StringIO.new
      HexaPDF::Document.new.tap {|d| d.pages.add; d.pages.add }.write(io)
      @ref[:F].embed(io, name: 'test.pdf')
      @ref[:Page] = 5
      assert_nil(@form.referenced_content)
    end

    it "returns nil if the page referenced by page label is not found" do
      io = StringIO.new
      HexaPDF::Document.new.tap do |d|
        d.pages.add
        d.pages.add
        d.pages.add_labelling_range(1, numbering_style: :decimal, prefix: 'Test')
      end.write(io)
      @ref[:F].embed(io, name: 'test.pdf')
      @ref[:Page] = 'Test5'
      assert_nil(@form.referenced_content)
    end

    it "returns nil if an error happens during processing" do
      @ref[:F].embed(StringIO.new('temp'), name: 'test.pdf')
      assert_nil(@form.referenced_content)
    end
  end
end
