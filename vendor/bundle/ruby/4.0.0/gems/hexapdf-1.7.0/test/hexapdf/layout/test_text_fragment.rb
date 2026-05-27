# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/layout/text_fragment'

# Numeric values were manually calculated using the information from the AFM file.
describe HexaPDF::Layout::TextFragment do
  before do
    @doc = HexaPDF::Document.new
    @font = @doc.fonts.add("Times", custom_encoding: true)
  end

  def setup_fragment(items, text_rise = 0)
    style = HexaPDF::Layout::Style.new(font: @font, font_size: 20,
                                       horizontal_scaling: 200, character_spacing: 1,
                                       word_spacing: 2, text_rise: text_rise)
    @fragment = HexaPDF::Layout::TextFragment.new(items, style)
  end

  describe "create" do
    it "creates a TextFragment from text and style" do
      frag = HexaPDF::Layout::TextFragment.create("Tom", font: @font, font_size: 20,
                                                  font_features: {kern: true})
      assert_equal(4, frag.items.length)
      assert_equal(36.18, frag.width)
      assert_equal(13.66 + 4.34, frag.height)
    end

    it "creates a TextFragment from text and a Style object" do
      style = HexaPDF::Layout::Style.new(font: @font)
      frag = HexaPDF::Layout::TextFragment.create("Tom", style)
      assert_equal(style, frag.style)
    end
  end

  describe "create_with_fallback_glyphs" do
    it "creates an array with a single fragment object if no block is given" do
      frags = HexaPDF::Layout::TextFragment.create_with_fallback_glyphs("Tom", font: @font, font_size: 20)
      assert_equal(1, frags.size)
      assert_equal(37.78, frags[0].width)
    end

    it "allows using a style object instead of directly specifying style properties" do
      style = HexaPDF::Layout::Style.new(font: @font, font_size: 20)
      frags = HexaPDF::Layout::TextFragment.create_with_fallback_glyphs("Tom", style)
      assert_equal(37.78, frags[0].width)
    end

    it "replaces invalid glyphs with the result of the block" do
      zapf_dingbats = @doc.fonts.add('ZapfDingbats')
      i = 0
      fallback = lambda do |codepoint, _invalid_glyph|
        case (i += 1) % 3
        when 0 then []
        when 1 then [zapf_dingbats.decode_codepoint(codepoint)]
        when 2 then @font.decode_utf8("Tom")
        end
      end
      style = HexaPDF::Layout::Style.new(font: @font, font_size: 20, font_features: {kern: true})

      frags = HexaPDF::Layout::TextFragment.create_with_fallback_glyphs("✂Tom✂✂Tom✂", style, &fallback)
      assert_equal(5, frags.size)
      assert_equal(zapf_dingbats, frags[0].style.font)
      assert_equal(:a2, frags[0].items[0].name)
      assert_equal(@font, frags[2].style.font)

      frags = HexaPDF::Layout::TextFragment.create_with_fallback_glyphs("Tom✂Tom", style, &fallback)
      assert_equal(3, frags.size)
      assert_equal(frags[0].width, frags[1].width)
    end
  end

  describe "initialize" do
    before do
      @items = @font.decode_utf8("Tom")
    end

    it "can use a Style object" do
      style = HexaPDF::Layout::Style.new(font: @font, font_size: 20)
      frag = HexaPDF::Layout::TextFragment.new(@items, style)
      assert_equal(20, frag.style.font_size)
    end

    it "can use style options" do
      frag = HexaPDF::Layout::TextFragment.new(@items, {font: @font, font_size: 20})
      assert_equal(20, frag.style.font_size)
    end
  end

  it "returns the text value of the items as string" do
    assert_equal("Hal lo\u{00a0}d\n", setup_fragment(@font.decode_utf8("Hal lo\u{00a0}d\n")).text)
  end

  it "allows duplicating with only its attributes while also setting new items" do
    setup_fragment([20])
    @fragment.properties['key'] = :value
    frag = @fragment.dup_attributes([21])
    assert_equal([21], frag.items)
    assert_same(frag.style, @fragment.style)
    assert_equal(:value, frag.properties['key'])
  end

  it "creates an attributes hash for storing the fragment based on the attributes without the items" do
    setup_fragment([20])
    hash = @fragment.attributes_hash
    @fragment.properties['key'] = :value
    new_hash = @fragment.attributes_hash
    refute_equal(hash, new_hash)
    @fragment.items << [21]
    assert_equal(new_hash, @fragment.attributes_hash)
  end

  it "allows setting custom properties" do
    setup_fragment([])
    @fragment.properties[:key] = :value
    assert_equal({key: :value}, @fragment.properties)
  end

  it "returns :text for valign" do
    assert_equal(:text, setup_fragment([]).valign)
  end

  describe "draw" do
    def setup_with_style(**styles)
      setup_fragment(@font.decode_utf8('H'), 2)
      styles.each {|name, value| @fragment.style.send(name, value) }
      @canvas = @doc.pages.add.canvas
      @fragment.draw(@canvas, 10, 15)
    end

    def assert_draw_operators(*args, front: [], middle: args, back: [])
      ops = [
        *front,
        [:set_font_and_size, [:F1, 20]],
        [:set_horizontal_scaling, [200]],
        [:set_character_spacing, [1]],
        [:set_word_spacing, [2]],
        [:set_text_rise, [2]],
        *middle,
        [:begin_text],
        [:move_text, [10, 15]],
        [:show_text, ['!']],
        *back,
      ].compact
      assert_operators(@canvas.contents, ops)
    end

    it "draws text onto the canvas" do
      setup_with_style
      assert_draw_operators
    end

    it "doesn't set the text properties if instructed to do so" do
      setup_fragment([])
      @canvas = @doc.pages.add.canvas
      @fragment.draw(@canvas, 10, 15, ignore_text_properties: true)
      assert_operators(@canvas.contents, [[:begin_text],
                                          [:move_text, [10, 15]]])
    end

    describe "uses an appropriate text position setter" do
      before do
        setup_fragment([])
        @canvas = @doc.pages.add.canvas
      end

      it "with text leading graphics state" do
        @canvas.begin_text.leading(10)
        @fragment.draw(@canvas, 0, -10, ignore_text_properties: true)
        assert_operators(@canvas.contents, [[:begin_text],
                                            [:set_leading, [10]],
                                            [:move_text_next_line]])
      end

      it "only horizontal movement" do
        @fragment.draw(@canvas, 20, 0, ignore_text_properties: true)
        assert_operators(@canvas.contents, [[:begin_text],
                                            [:move_text, [20, 0]]])
      end

      it "only vertical movement" do
        @fragment.draw(@canvas, 0, 10, ignore_text_properties: true)
        assert_operators(@canvas.contents, [[:begin_text],
                                            [:move_text, [0, 10]]])
      end

      it "horizontal and vertical movement" do
        @fragment.draw(@canvas, 10, 10, ignore_text_properties: true)
        assert_operators(@canvas.contents, [[:begin_text],
                                            [:move_text, [10, 10]]])
      end
    end

    it "draws styled filled text" do
      setup_with_style(fill_color: 0.5, fill_alpha: 0.5)
      assert_draw_operators([:set_graphics_state_parameters, [:GS1]],
                            [:set_device_gray_non_stroking_color, [0.5]])
      assert_equal({Type: :ExtGState, CA: 1, ca: 0.5}, @canvas.resources[:ExtGState][:GS1])
    end

    it "draws style stroked text" do
      setup_with_style(text_rendering_mode: :stroke,
                       stroke_color: [1.0, 0, 0], stroke_alpha: 0.5, stroke_width: 2,
                       stroke_cap_style: :round, stroke_join_style: :round, stroke_miter_limit: 5,
                       stroke_dash_pattern: [1, 2, 3])
      assert_draw_operators([:set_text_rendering_mode, [1]],
                            [:set_graphics_state_parameters, [:GS1]],
                            [:set_device_rgb_stroking_color, [1, 0, 0]],
                            [:set_line_width, [2]],
                            [:set_line_cap_style, [1]],
                            [:set_line_join_style, [1]],
                            [:set_miter_limit, [5]],
                            [:set_line_dash_pattern, [[1, 2, 3], 0]])
      assert_equal({Type: :ExtGState, CA: 0.5, ca: 1}, @canvas.resources[:ExtGState][:GS1])
    end

    it "invokes the underlays" do
      setup_with_style(underlays: [proc { @canvas.stroke_color(0.5) }])
      assert_draw_operators(front: [[:save_graphics_state],
                                    [:concatenate_matrix, [1, 0, 0, 1, 10, 15 + @fragment.y_min]],
                                    [:save_graphics_state],
                                    [:set_device_gray_stroking_color, [0.5]],
                                    [:restore_graphics_state],
                                    [:restore_graphics_state]])
    end

    it "invokes the overlays" do
      setup_with_style(overlays: [proc { @canvas.stroke_color(0.5) }])
      assert_draw_operators(back: [[:end_text],
                                   [:save_graphics_state],
                                   [:concatenate_matrix, [1, 0, 0, 1, 10, 15 + @fragment.y_min]],
                                   [:save_graphics_state],
                                   [:set_device_gray_stroking_color, [0.5]],
                                   [:restore_graphics_state],
                                   [:restore_graphics_state]])
    end

    it "draws the underline" do
      setup_with_style(underline: true, text_rendering_mode: :stroke,
                       stroke_width: 5, stroke_color: [0.5], stroke_cap_style: :round,
                       stroke_dash_pattern: 5)
      assert_draw_operators(middle: [[:set_text_rendering_mode, [1]],
                                     [:set_device_gray_stroking_color, [0.5]],
                                     [:set_line_width, [5]],
                                     [:set_line_cap_style, [1]],
                                     [:set_line_dash_pattern, [[5], 0]]],
                            back: [[:end_text],
                                   [:save_graphics_state],
                                   [:set_device_gray_stroking_color, [0]],
                                   [:set_line_width, [@fragment.style.calculated_underline_thickness]],
                                   [:set_line_cap_style, [0]],
                                   [:set_line_dash_pattern, [[], 0]],
                                   [:move_to, [10, 15]],
                                   [:line_to, [40.88, 15]],
                                   [:stroke_path],
                                   [:restore_graphics_state]])
    end

    it "draws the strikeout line" do
      setup_with_style(strikeout: true, text_rendering_mode: :stroke,
                       stroke_width: 5, stroke_color: [0.5], stroke_cap_style: :round,
                       stroke_dash_pattern: 5)
      assert_draw_operators(middle: [[:set_text_rendering_mode, [1]],
                                     [:set_device_gray_stroking_color, [0.5]],
                                     [:set_line_width, [5]],
                                     [:set_line_cap_style, [1]],
                                     [:set_line_dash_pattern, [[5], 0]]],
                            back: [[:end_text],
                                   [:save_graphics_state],
                                   [:set_device_gray_stroking_color, [0]],
                                   [:set_line_width, [@fragment.style.calculated_strikeout_thickness]],
                                   [:set_line_cap_style, [0]],
                                   [:set_line_dash_pattern, [[], 0]],
                                   [:move_to, [10, 21.01]],
                                   [:line_to, [40.88, 21.01]],
                                   [:stroke_path],
                                   [:restore_graphics_state]])
    end
  end

  describe "empty fragment" do
    before do
      setup_fragment([])
    end

    it "calculates the x_min" do
      assert_equal(0, @fragment.x_min)
    end

    it "calculates the x_max" do
      assert_equal(0, @fragment.x_max)
    end

    it "calculates the y_min" do
      assert_equal(-4.34, @fragment.y_min)
    end

    it "calculates the y_max" do
      assert_equal(13.66, @fragment.y_max)
    end

    it "calculates the width" do
      assert_equal(0, @fragment.width)
    end

    it "calculates the height" do
      assert_equal(13.66 + 4.34, @fragment.height)
    end
  end

  describe "normal text" do
    before do
      setup_fragment(@font.decode_utf8("Hal lo").insert(2, -35).insert(1, -10))
    end

    it "calculates the x_min" do
      assert_in_delta(0.76, @fragment.x_min)
    end

    it "calculates the x_max" do
      assert_in_delta(116.68 - 1.2 - 2, @fragment.x_max)
    end

    it "calculates the exact y_min" do
      assert_in_delta(-0.2, @fragment.exact_y_min)
    end

    it "calculates the exact y_max" do
      assert_in_delta(13.66, @fragment.exact_y_max)
    end

    it "calculates the y_min" do
      assert_in_delta(-4.34, @fragment.y_min)
    end

    it "calculates the y_max" do
      assert_in_delta(13.66, @fragment.y_max)
    end

    it "calculates the width" do
      assert_in_delta(116.68, @fragment.width)
    end

    it "calculates the height" do
      assert_in_delta(13.66 + 4.34, @fragment.height)
    end
  end

  describe "with a positive text rise" do
    before do
      setup_fragment(@font.decode_utf8("l,"), 4)
    end

    it "calculates the y_min" do
      assert_in_delta(-4.34 + 4, @fragment.y_min)
    end

    it "calculates the y_max" do
      assert_in_delta(13.66 + 4, @fragment.y_max)
    end

    it "calculates the height" do
      assert_in_delta(13.66 + 4 + 0.34, @fragment.height)
    end
  end

  describe "with a negative text rise" do
    before do
      setup_fragment(@font.decode_utf8("l,"), -15)
    end

    it "calculates the y_min" do
      assert_in_delta(-4.34 - 15, @fragment.y_min)
    end

    it "calculates the y_max" do
      assert_in_delta(13.66 - 15, @fragment.y_max)
    end

    it "calculates the height" do
      assert_in_delta(4.34 + 15, @fragment.height)
    end
  end

  describe "with a glyph without outline as last item" do
    before do
      setup_fragment(@font.decode_utf8("H "))
    end

    it "calculates the x_max" do
      assert_in_delta(46.88 - 2 - 4, @fragment.x_max)
    end

    it "calculates the width" do
      assert_in_delta(46.88, @fragment.width)
    end
  end

  describe "with a glyph with x_min < 0 and x_max > width as first and last item" do
    before do
      setup_fragment(@font.decode_utf8("\u{2044}o\u{2044}".unicode_normalize(:nfd)))
    end

    it "calculates the x_min" do
      assert_in_delta(-6.72, @fragment.x_min)
    end

    it "calculates the x_max" do
      assert_in_delta(39.36 + 6.56 - 2, @fragment.x_max)
    end

    it "calculates the width" do
      assert_in_delta(39.36, @fragment.width)
    end
  end

  describe "with positive kerning values as first and last items" do
    before do
      setup_fragment([100, 100] + @font.decode_utf8("Hallo") + [100, 100])
    end

    it "calculates the x_min" do
      assert_in_delta(-7.24, @fragment.x_min)
    end

    it "calculates the x_max" do
      assert_in_delta(82.88 - 1.2 - 2 - -4 - -4, @fragment.x_max)
    end

    it "calculates the width" do
      assert_in_delta(82.88, @fragment.width)
    end
  end

  describe "fill_horizontal!" do
    before do
      @fragment = HexaPDF::Layout::TextFragment.create('ab', fill_horizontal: 1, font: @font)
    end

    it "returns the fragment if the given width is too small" do
      assert_same(@fragment, @fragment.fill_horizontal!(0.1))
    end

    it "repeats all items of the fragment" do
      fragment = @fragment.fill_horizontal!(@fragment.width * 2)
      assert_equal([*(@fragment.items * 2), 0], fragment.items)
      assert_in_delta(@fragment.width * 2, fragment.width)
    end

    it "adds, after repeating, items from the start of the fragment to fill the available space" do
      fragment = @fragment.fill_horizontal!(90)
      assert_equal([*(@fragment.items * 9), @fragment.items[0], 3.3333333333332673], fragment.items)
      assert_in_delta(90, fragment.width)
    end

    it "sets the character spacing correctly to account for the remaining space after filling with items" do
      fragment = @fragment.fill_horizontal!(90)
      refute_same(@fragment.style, fragment.style)
      assert_equal(0.033333333333332674, fragment.style.character_spacing)
      assert_in_delta(90, fragment.width)
    end
  end

  it "can be inspected" do
    frag = setup_fragment(@font.decode_utf8("H") << 5)
    assert_match(/:H/, frag.inspect)
  end
end
