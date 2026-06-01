# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'hexapdf/document'
require 'hexapdf/type/page'

describe HexaPDF::Type::Page do
  before do
    @doc = HexaPDF::Document.new
  end

  describe "::media_box" do
    it "returns the media box for a given paper size" do
      assert_equal([0, 0, 595.275591, 841.889764], HexaPDF::Type::Page.media_box(:A4))
    end

    it "respects the orientation key" do
      assert_equal([0, 0, 841.889764, 595.275591],
                   HexaPDF::Type::Page.media_box(:A4, orientation: :landscape))
    end

    it "works with a paper size array" do
      assert_equal([0, 0, 842, 595], HexaPDF::Type::Page.media_box([0, 0, 842, 595]))
    end

    it "fails if the paper size is unknown" do
      assert_raises(HexaPDF::Error) { HexaPDF::Type::Page.media_box(:Unknown) }
    end

    it "fails if the array doesn't contain four numbers" do
      assert_raises(HexaPDF::Error) { HexaPDF::Type::Page.media_box([0, 1, 2]) }
    end

    it "fails if the array doesn't contain only numbers" do
      assert_raises(HexaPDF::Error) { HexaPDF::Type::Page.media_box([0, 1, 2, 'a']) }
    end
  end

  # Asserts that the page's contents contains the operators.
  def assert_page_operators(page, operators)
    processor = HexaPDF::TestUtils::OperatorRecorder.new
    page.process_contents(processor)
    assert_equal(operators, processor.recorded_ops)
  end

  it "must always be indirect" do
    page = @doc.add({Type: :Page})
    page.must_be_indirect = false
    assert(page.must_be_indirect?)
  end

  describe "[]" do
    before do
      @root = @doc.add({Type: :Pages})
      @kid = @doc.add({Type: :Pages, Parent: @root})
      @page = @doc.add({Type: :Page, Parent: @kid})
    end

    it "works normal for non-inheritable fields" do
      assert_equal(:Page, @page[:Type])
      assert_nil(@page[:Dur])
    end

    it "automatically retrieves inherited values" do
      @root[:MediaBox] = :media
      assert_equal(:media, @page[:MediaBox])

      @root[:Resources] = :root_res
      @kid[:Resources] = :res
      assert_equal(:res, @page[:Resources])

      @page[:CropBox] = :cropbox
      assert_equal(:cropbox, @page[:CropBox])

      @kid[:Rotate] = :kid_rotate
      assert_equal(:kid_rotate, @page[:Rotate])
    end

    it "returns nil or the default value if no value is set anywhere" do
      assert_nil(@page[:MediaBox])
      assert_equal(0, @page[:Rotate])
    end
  end

  describe "perform_validation" do
    it "only does validation if the page is in the document's page tree" do
      page = @doc.add({Type: :Page})
      assert(page.validate(auto_correct: false))
      page[:Parent] = @doc.add({Type: :Pages, Kids: [page], Count: 1})
      assert(page.validate(auto_correct: false))
      @doc.pages.add(page)
      refute(page.validate(auto_correct: false))
    end

    it "validates that the required inheritable field /Resources is set" do
      page = @doc.pages.add
      page.delete(:Resources)
      refute(page.validate(auto_correct: false))
      assert(page.validate)
      assert_kind_of(HexaPDF::Dictionary, page[:Resources])
    end

    it "validates that the required inheritable field /MediaBox is set" do
      page1 = @doc.pages.add(:Letter)
      page2 = @doc.pages.add(:Letter)
      page3 = @doc.pages.add(:Letter)

      [page1, page2, page3].each do |page|
        page.delete(:MediaBox)
        refute(page.validate(auto_correct: false))
        assert(page.validate)
        assert_equal([0, 0, 612, 792], page[:MediaBox])
      end

      page2.delete(:MediaBox)
      page1[:MediaBox] = [0, 0, 1, 1]
      refute(page2.validate(auto_correct: false))
      assert(page2.validate)
      assert_equal([0, 0, 595.275591, 841.889764], page2[:MediaBox])
    end
  end

  describe "box" do
    before do
      @page = @doc.pages.add
    end

    it "returns the crop box by default" do
      @page[:CropBox] = [0, 0, 100, 200]
      assert_equal([0, 0, 100, 200], @page.box)
    end

    it "returns the correct media box" do
      @page[:MediaBox] = :media
      assert_equal(:media, @page.box(:media))
    end

    it "returns the correct crop box" do
      @page[:MediaBox] = [0, 0, 10, 10]
      assert_equal([0, 0, 10, 10], @page.box(:crop))
      @page[:CropBox] = [0, 0, 5, 5]
      assert_equal([0, 0, 5, 5], @page.box(:crop))
    end

    it "returns the correct bleed, trim and art boxes" do
      @page[:MediaBox] = mb = [0, 0, 10, 10]
      assert_equal(mb, @page.box(:bleed))
      assert_equal(mb, @page.box(:trim))
      assert_equal(mb, @page.box(:art))
      @page[:CropBox] = cb = [0, 0, 8, 8]
      assert_equal(cb, @page.box(:bleed))
      assert_equal(cb, @page.box(:trim))
      assert_equal(cb, @page.box(:art))
      @page[:BleedBox] = [0, 0, 0, 5]
      @page[:TrimBox] = [0, 0, 0, 7]
      @page[:ArtBox] = [0, 0, 0, 1]
      assert_equal([0, 0, 0, 5], @page.box(:bleed))
      assert_equal([0, 0, 0, 7], @page.box(:trim))
      assert_equal([0, 0, 0, 1], @page.box(:art))
    end

    it "restricts all boxes to the bounds of the media box" do
      @page[:MediaBox] = [10, 20, 100, 200]
      @page[:CropBox] = [0, 0, 200, 300]
      assert_equal([10, 20, 100, 200], @page.box.value)
    end

    it "returns a zero-sized box if requested box doesn't overlap with the media box" do
      @page[:MediaBox] = [0, 0, 100, 100]

      @page[:CropBox] = [-20, 0, -10, 100]
      assert_equal([0, 0, 0, 0], @page.box)
      @page[:CropBox] = [200, 0, 250, 100]
      assert_equal([0, 0, 0, 0], @page.box)
      @page[:CropBox] = [0, 110, 100, 150]
      assert_equal([0, 0, 0, 0], @page.box)
      @page[:CropBox] = [0, -100, 100, -10]
      assert_equal([0, 0, 0, 0], @page.box)
    end

    it "fails if an unknown box type is supplied" do
      assert_raises(ArgumentError) { @page.box(:undefined) }
    end

    it "sets the correct box" do
      @page.box(:media, [0, 0, 1, 1])
      assert_equal([0, 0, 1, 1], @page.box(:media).value)

      @page.box(:media, [0, 0, 1, 10])
      @page.box(:crop, [0, 0, 1, 2])
      assert_equal([0, 0, 1, 2], @page.box(:crop).value)
      @page.box(:bleed, [0, 0, 1, 3])
      assert_equal([0, 0, 1, 3], @page.box(:bleed))
      @page.box(:trim, [0, 0, 1, 4])
      assert_equal([0, 0, 1, 4], @page.box(:trim))
      @page.box(:art, [0, 0, 1, 5])
      assert_equal([0, 0, 1, 5], @page.box(:art))
    end

    it "fails if an unknown box type is supplied when setting a box" do
      assert_raises(ArgumentError) { @page.box(:undefined, [1, 2, 3, 4]) }
    end
  end

  describe "orientation" do
    before do
      @page = @doc.pages.add
    end

    it "uses the crop box by default" do
      @page[:CropBox] = [0, 0, 200, 100]
      assert_equal(:landscape, @page.orientation)
    end

    it "uses the specified box for determining the orientation" do
      @page[:ArtBox] = [0, 0, 200, 100]
      assert_equal(:landscape, @page.orientation(:art))
    end

    it "returns :portrait for appropriate boxes and rotation values" do
      @page.box(:crop, [0, 0, 100, 300])
      assert_equal(:portrait, @page.orientation)
      @page[:Rotate] = 0
      assert_equal(:portrait, @page.orientation)
      @page[:Rotate] = 180
      assert_equal(:portrait, @page.orientation)

      @page.box(:crop, [0, 0, 300, 100])
      @page[:Rotate] = 90
      assert_equal(:portrait, @page.orientation)
      @page[:Rotate] = 270
      assert_equal(:portrait, @page.orientation)
    end

    it "returns :landscape for appropriate media boxes and rotation values" do
      @page.box(:crop, [0, 0, 300, 100])
      assert_equal(:landscape, @page.orientation)
      @page[:Rotate] = 0
      assert_equal(:landscape, @page.orientation)
      @page[:Rotate] = 180
      assert_equal(:landscape, @page.orientation)

      @page.box(:crop, [0, 0, 100, 300])
      @page[:Rotate] = 90
      assert_equal(:landscape, @page.orientation)
      @page[:Rotate] = 270
      assert_equal(:landscape, @page.orientation)
    end
  end

  describe "rotate" do
    before do
      @page = @doc.pages.add
      reset_media_box
    end

    def reset_media_box
      @page.box(:media, [50, 100, 200, 300])
    end

    it "works directly on the :Rotate key" do
      @page.rotate(90)
      assert_equal(270, @page[:Rotate])

      @page.rotate(180)
      assert_equal(90, @page[:Rotate])

      @page.rotate(-90)
      assert_equal(180, @page[:Rotate])
    end

    describe "flatten" do
      it "adjust all page boxes" do
        @page.box(:crop, [50, 100, 200, 300])
        @page.box(:bleed, [60, 110, 190, 290])
        @page.box(:trim, [70, 120, 180, 280])
        @page.box(:art, [80, 130, 170, 270])

        @page.rotate(90, flatten: true)
        assert_equal([0, 0, 200, 150], @page.box(:media).value)
        assert_equal([0, 0, 200, 150], @page.box(:crop).value)
        assert_equal([10, 10, 190, 140], @page.box(:bleed).value)
        assert_equal([20, 20, 180, 130], @page.box(:trim).value)
        assert_equal([30, 30, 170, 120], @page.box(:art).value)
      end

      it "works correctly for 90 degrees" do
        @page.rotate(90, flatten: true)
        assert_equal([0, 0, 200, 150], @page.box(:media).value)
        assert_equal(" q 0 1 -1 0 300 -50 cm   Q ", @page.contents)
      end

      it "works correctly for 180 degrees" do
        @page.rotate(180, flatten: true)
        assert_equal([0, 0, 150, 200], @page.box(:media).value)
        assert_equal(" q -1 0 0 -1 200 300 cm   Q ", @page.contents)
      end

      it "works correctly for 270 degrees" do
        @page.rotate(270, flatten: true)
        assert_equal([0, 0, 200, 150], @page.box(:media).value)
        assert_equal(" q 0 -1 1 0 -100 200 cm   Q ", @page.contents)
      end

      describe "annotations" do
        before do
          @appearance = @doc.add({Type: :XObject, Subtype: :Form, BBox: [-10, -5, 50, 20]}, stream: "")
          @annot = @doc.add({Type: :Annot, Subtype: :Widget, Rect: [100, 100, 160, 125],
                             QuadPoints: [0, 0, 100, 200, 300, 400, 500, 600],
                             AP: {N: @appearance}})
          @page[:Annots] = [@annot]
        end

        it "rotates the /Rect entry" do
          @page.rotate(90, flatten: true)
          assert_equal([175, 50, 200, 110], @annot[:Rect].value)
        end

        it "rotates all (x,y) pairs in the /QuadPoints entry" do
          @page.rotate(90, flatten: true)
          assert_equal([300, -50, 100, 50, -100, 250, -300, 450],
                       @annot[:QuadPoints])
        end

        it "applies the needed matrix to the annotation's appearance stream's /Matrix entry" do
          @page.rotate(90, flatten: true)
          assert_equal([0, 1, -1, 0, 300, -50], @appearance[:Matrix])

          @page.rotate(90, flatten: true)
          assert_equal([-1, 0, 0, -1, 200, 300], @appearance[:Matrix])
        end

        it "modified the /R entry in the appearance characteristics dictionary of a widget annotation" do
          @page.rotate(90, flatten: true)
          assert_equal(90, @annot[:MK][:R])

          @page.rotate(90, flatten: true)
          assert_equal(180, @annot[:MK][:R])
        end
      end
    end

    it "fails if the angle is not a multiple of 90" do
      assert_raises(ArgumentError) { @page.rotate(27) }
    end
  end

  describe "contents" do
    it "returns the contents of a single content stream" do
      page = @doc.pages.add
      page[:Contents] = @doc.wrap({}, stream: 'q 10 w Q')
      assert_equal('q 10 w Q', page.contents)
    end

    it "returns the concatenated contents of multiple content stream" do
      page = @doc.pages.add
      page[:Contents] = [@doc.wrap({}, stream: 'q 10'), @doc.wrap({}, stream: 'w Q')]
      assert_equal('q 10 w Q', page.contents)
    end

    it "handles null objects in the /Contents array" do
      page = @doc.pages.add
      page[:Contents] = [@doc.wrap({}, stream: 'q 10'), nil]
      assert_equal('q 10 ', page.contents)
    end
  end

  describe "contents=" do
    it "creates a content stream if none already exist" do
      page = @doc.pages.add
      page.contents = 'test'
      assert_equal('test', page[:Contents].stream)
    end

    it "reuses an existing content stream" do
      page = @doc.pages.add
      page[:Contents] = content = @doc.wrap({}, stream: 'q 10 w Q')
      page.contents = 'test'
      assert_equal(content, page[:Contents])
      assert_equal('test', content.stream)
    end

    it "reuses the first content stream and deletes the rest if more than one exist" do
      page = @doc.pages.add
      page[:Contents] = [content = @doc.add({}, stream: 'q 10 w Q'), @doc.add({}, stream: 'q Q')]
      page.contents = 'test'
      assert_equal(content, page[:Contents])
      assert_equal('test', content.stream)
    end
  end

  describe "resources" do
    it "creates the resource dictionary if it is not found" do
      page = @doc.add({Type: :Page, Parent: @doc.pages.root})
      resources = page.resources
      assert_equal(:XXResources, resources.type)
      assert_equal({}, resources.value)
    end

    it "returns the already used resource dictionary" do
      @doc.pages.root[:Resources] = {Font: {F1: nil}}
      page = @doc.pages.add(@doc.add({Type: :Page}))
      resources = page.resources
      assert_equal(:XXResources, resources.type)
      assert_equal(@doc.pages.root[:Resources], resources)
    end
  end

  describe "process_contents" do
    it "parses the contents and processes it" do
      page = @doc.pages.add
      page[:Contents] = @doc.wrap({}, stream: 'q 10 w Q')
      assert_page_operators(page, [[:save_graphics_state], [:set_line_width, [10]],
                                   [:restore_graphics_state]])
    end
  end

  describe "extract_text" do
    it "extracts the layouted text from the page" do
      page = @doc.pages.add
      page.canvas.font('Helvetica', size: 10).text('Hello', at: [10, 10])
      assert_equal('Hello', page.extract_text(line_tolerance_factor: 5))
    end
  end

  describe "index" do
    it "returns the index of the page in the page tree" do
      kid1 = @doc.add({Type: :Pages, Parent: @doc.pages.root, Count: 4})
      @doc.pages.root[:Kids] << kid1

      kid11 = @doc.add({Type: :Pages, Parent: kid1})
      page1 = kid11.add_page
      kid1[:Kids] << kid11
      page2 = kid1.add_page
      kid12 = @doc.add({Type: :Pages, Parent: kid1})
      page3 = kid12.add_page
      page4 = kid12.add_page
      kid1[:Kids] << kid12

      assert_equal(0, page1.index)
      assert_equal(1, page2.index)
      assert_equal(2, page3.index)
      assert_equal(3, page4.index)
    end
  end

  describe "label" do
    it "returns the label for the page" do
      5.times { @doc.pages.add }
      @doc.pages.add_labelling_range(0, numbering_style: :uppercase_letters)
      assert_equal(%w[A B C D E], @doc.pages.each.map(&:label))
    end
  end

  it "returns all ancestor page tree nodes of a page" do
    root = @doc.add({Type: :Pages})
    kid = @doc.add({Type: :Pages, Parent: root})
    page = @doc.add({Type: :Page, Parent: kid})
    assert_equal([kid, root], page.ancestor_nodes)
  end

  describe "canvas" do
    before do
      @page = @doc.pages.add
    end

    it "works correctly if invoked on an empty page, using type :page in first invocation" do
      @page.canvas.line_width = 10
      assert_page_operators(@page, [[:set_line_width, [10]]])

      @page.canvas(type: :overlay).line_width = 5
      assert_page_operators(@page, [[:save_graphics_state], [:restore_graphics_state],
                                    [:save_graphics_state], [:set_line_width, [10]],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:set_line_width, [5]], [:restore_graphics_state]])

      @page.canvas(type: :underlay).line_width = 2
      assert_page_operators(@page, [[:save_graphics_state], [:set_line_width, [2]],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:set_line_width, [10]],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:set_line_width, [5]], [:restore_graphics_state]])
    end

    it "works correctly if invoked on an empty page, using type :underlay in first invocation" do
      @page.canvas(type: :underlay).line_width = 2
      assert_page_operators(@page, [[:save_graphics_state], [:set_line_width, [2]],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:restore_graphics_state]])

      @page.canvas.line_width = 10
      assert_page_operators(@page, [[:save_graphics_state], [:set_line_width, [2]],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:set_line_width, [10]], [:restore_graphics_state],
                                    [:save_graphics_state], [:restore_graphics_state]])

      @page.canvas(type: :overlay).line_width = 5
      assert_page_operators(@page, [[:save_graphics_state], [:set_line_width, [2]],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:set_line_width, [10]],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:set_line_width, [5]], [:restore_graphics_state]])
    end

    it "works correctly if invoked on a page with existing contents" do
      @page.contents = "10 w"

      @page.canvas(type: :overlay).line_width = 5
      assert_page_operators(@page, [[:save_graphics_state], [:restore_graphics_state],
                                    [:save_graphics_state], [:set_line_width, [10]],
                                    [:restore_graphics_state],
                                    [:save_graphics_state], [:set_line_width, [5]],
                                    [:restore_graphics_state]])

      @page.canvas(type: :underlay).line_width = 2
      assert_page_operators(@page, [[:save_graphics_state], [:set_line_width, [2]],
                                    [:restore_graphics_state], [:save_graphics_state],
                                    [:set_line_width, [10]],
                                    [:restore_graphics_state],
                                    [:save_graphics_state], [:set_line_width, [5]],
                                    [:restore_graphics_state]])
    end

    it "works correctly if the page has its crop box origin not at (0,0)" do
      @page.box(:media, [-20, -20, 100, 300])
      @page.box(:crop, [-10, -5, 100, 300])
      @page.canvas(type: :underlay).line_width = 2
      @page.canvas(type: :page).line_width = 2
      @page.canvas(type: :overlay).line_width = 2

      assert_page_operators(@page, [[:save_graphics_state],
                                    [:concatenate_matrix, [1, 0, 0, 1, -10, -5]],
                                    [:set_line_width, [2]],
                                    [:restore_graphics_state],

                                    [:save_graphics_state],
                                    [:concatenate_matrix, [1, 0, 0, 1, -10, -5]],
                                    [:set_line_width, [2]],
                                    [:restore_graphics_state],

                                    [:save_graphics_state],
                                    [:concatenate_matrix, [1, 0, 0, 1, -10, -5]],
                                    [:set_line_width, [2]],
                                    [:restore_graphics_state]])
    end

    it "allows disabling the origin translation" do
      @page.box(:crop, [-10, -5, 100, 300])
      @page.canvas(translate_origin: false).line_width = 2

      assert_page_operators(@page, [[:set_line_width, [2]]])
    end

    it "fails if the page canvas is requested for a page with existing contents" do
      @page.contents = "q Q"
      assert_raises(HexaPDF::Error) { @page.canvas }
    end

    it "fails if called with an incorrect type argument" do
      assert_raises(ArgumentError) { @page.canvas(type: :something) }
    end
  end

  describe "to_form_xobject" do
    it "creates an independent form xobject" do
      page = @doc.pages.add
      page.contents = "test"
      form = page.to_form_xobject
      refute(form.indirect?)
      assert_equal(form.box.value, page.box.value)
    end

    it "works for pages without content" do
      page = @doc.pages.add
      form = page.to_form_xobject
      assert_equal('', form.stream)
    end

    it "uses the raw stream data if possible to avoid unnecessary work" do
      page = @doc.pages.add
      page.contents = HexaPDF::StreamData.new(StringIO.new("test"))
      form = page.to_form_xobject
      assert_same(form.raw_stream, page[:Contents].raw_stream)

      form = page.to_form_xobject(reference: false)
      refute_same(form.raw_stream, page[:Contents].raw_stream)
    end
  end

  describe "flatten_annotations" do
    before do
      @page = @doc.pages.add
      @appearance = @doc.add({Type: :XObject, Subtype: :Form, BBox: [-10, -5, 50, 20]}, stream: "")
      @annot1 = @doc.add({Type: :Annot, Subtype: :Text, Rect: [100, 100, 160, 125], AP: {N: @appearance}})
      @annot2 = @doc.add({Type: :Annot, Subtype: :Text, Rect: [10, 10, 70, 35], AP: {N: @appearance}})
      @page[:Annots] = [@annot1, @annot2]
      @canvas = @page.canvas(type: :overlay)
    end

    it "does nothing and returns the argument as array if the page doesn't have any annotations" do
      annots = @page[:Annots]

      @page.delete(:Annots)
      result = @page.flatten_annotations
      assert(result.empty?)
      assert_operators(@canvas.contents, [])

      result = @page.flatten_annotations(annots)
      assert_kind_of(Array, result)
      assert_equal([@annot1, @annot2], result)
      assert_operators(@canvas.contents, [])
    end

    it "flattens all annotations of the page by default" do
      result = @page.flatten_annotations
      assert(result.empty?)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:concatenate_matrix, [1.0, 0, 0, 1.0, 110, 105]],
                                          [:paint_xobject, [:XO1]],
                                          [:restore_graphics_state],
                                          [:save_graphics_state],
                                          [:concatenate_matrix, [1.0, 0, 0, 1.0, 20, 15]],
                                          [:paint_xobject, [:XO1]],
                                          [:restore_graphics_state]])
      assert(@annot1.null?)
      assert(@annot2.null?)
    end

    it "gracefully handles duplicate annotations that should be flattened" do
      @page[:Annots] << @annot1
      result = @page.flatten_annotations
      assert(result.empty?)
    end

    it "gracefully handles invalid /Annot key values" do
      @page[:Annots] << nil << @doc.add({}, stream: '') << 543
      result = @page.flatten_annotations
      assert(result.empty?)
      assert(@annot1.null?)
      assert(@annot2.null?)
      assert_equal([], @page[:Annots].value)

      @page[:Annots] = @doc.add({}, stream: '')
      result = @page.flatten_annotations
      assert(result.empty?)
    end

    it "only deletes the widget annotation of a form field even if it is embedded in the field object" do
      form = @doc.acro_form(create: true)
      field = form.create_text_field('test')
      widget = field.create_widget(@page, Rect: [200, 200, 250, 215])
      field.field_value = 'hello'

      assert_same(widget.data, field.data)
      result = @page.flatten_annotations([widget])
      assert(result.empty?)
      refute(field.null?)
    end

    it "does nothing if a given annotation is not part of the page" do
      annots = [{Test: :Object}]
      result = @page.flatten_annotations(annots)
      assert_equal(annots, result)
    end

    it "deletes hidden annotations but doesn't include them in the content stream" do
      @annot1.flag(:hidden)
      result = @page.flatten_annotations
      assert(result.empty?)
      assert(@annot1.null?)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:concatenate_matrix, [1.0, 0, 0, 1.0, 20, 15]],
                                          [:paint_xobject, [:XO1]],
                                          [:restore_graphics_state]])
    end

    it "deletes invisible annotations but doesn't include them in the content stream" do
      @annot1.flag(:invisible)
      result = @page.flatten_annotations
      assert(result.empty?)
      assert(@annot1.null?)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:concatenate_matrix, [1.0, 0, 0, 1.0, 20, 15]],
                                          [:paint_xobject, [:XO1]],
                                          [:restore_graphics_state]])
    end

    it "ignores annotations without appearance stream" do
      @annot1.delete(:AP)
      result = @page.flatten_annotations
      assert_equal([@annot1], result)
      refute(@annot1.empty?)
      assert_operators(@canvas.contents, [[:save_graphics_state],
                                          [:concatenate_matrix, [1.0, 0, 0, 1.0, 20, 15]],
                                          [:paint_xobject, [:XO1]],
                                          [:restore_graphics_state]])
    end

    it "handles degenerate cases when the appearance's bounding box has zero width" do
      @appearance[:BBox] = [10, 10, 10, 20]
      result = @page.flatten_annotations
      assert(result.empty?)
      assert(@annot1.null?)
      assert_operators(@canvas.contents, [])
    end

    it "handles degenerate cases when the appearance's bounding box has zero height" do
      @appearance[:BBox] = [10, 10, 20, 10]
      result = @page.flatten_annotations
      assert(result.empty?)
      assert(@annot1.null?)
      assert_operators(@canvas.contents, [])
    end

    it "potentially adjusts the origin so that it is always in (0,0)" do
      @canvas.translate(-15, -15)
      @page.flatten_annotations
      assert_operators(@canvas.contents, [:concatenate_matrix, [1, 0, 0, 1, 15, 15]], range: 2)
    end

    it "adjusts the position in case the form /Matrix has an offset" do
      @appearance[:Matrix] = [1, 0, 0, 1, 15, 15]
      @page.flatten_annotations
      assert_operators(@canvas.contents, [:concatenate_matrix, [1, 0, 0, 1, 95, 90]], range: 1)
    end

    it "adjusts the position for an appearance with a 90 degree rotation" do
      @appearance[:Matrix] = [0, 1, -1, 0, 0, 0]
      @annot1[:Rect] = [100, 100, 125, 160]
      @page.flatten_annotations
      assert_operators(@canvas.contents, [:concatenate_matrix, [1, 0, 0, 1, 120, 110]], range: 1)
    end

    it "adjusts the position for an appearance with a -90 degree rotation" do
      @appearance[:Matrix] = [0, -1, 1, 0, 0, 0]
      @annot1[:Rect] = [100, 100, 125, 160]
      @page.flatten_annotations
      assert_operators(@canvas.contents, [:concatenate_matrix, [1, 0, 0, 1, 105, 150]], range: 1)
    end

    it "adjusts the position for an appearance with a 180 degree rotation" do
      @appearance[:Matrix] = [-1, 0, 0, -1, 0, 0]
      @page.flatten_annotations
      assert_operators(@canvas.contents, [:concatenate_matrix, [1, 0, 0, 1, 150, 120]], range: 1)
    end

    it "correctly positions and scales an appearance with a custom rotation" do
      @appearance[:Matrix] = [0.707106, 0.707106, -0.707106, 0.707106, 10, 30]
      @page.flatten_annotations
      assert_operators(@canvas.contents,
                       [:concatenate_matrix, [0.998269, 0.0, 0.0, 0.415946, 111.193776, 91.933396]],
                       range: 1)
    end

    it "scales the appearance to fit into the annotations's rectangle" do
      @annot1[:Rect] = [100, 100, 130, 150]
      @page.flatten_annotations
      assert_operators(@canvas.contents, [:concatenate_matrix, [0.5, 0, 0, 2, 105, 110]], range: 1)
    end
  end

  it "yields each annotation" do
    page = @doc.pages.add
    annot1 = @doc.add({Type: :Annot, Subtype: :Text, Rect: [100, 100, 160, 125]})
    annot2 = @doc.add({Subtype: :Unknown, Rect: [10, 10, 70, 35]})
    not_an_annot = @doc.add({}, stream: '')
    page[:Annots] = [not_an_annot, annot1, nil, annot2, {Type: :Annot, Subtype: :Text, Rect: [0, 0, 0, 0]}]

    annotations = page.each_annotation.to_a
    assert_equal(3, annotations.size)
    assert_equal([100, 100, 160, 125], annotations[0][:Rect])
    assert_equal(:Annot, annotations[0].type)
    assert_equal(:Annot, annotations[1].type)
    assert_equal(:Annot, annotations[2].type)
  end
end
