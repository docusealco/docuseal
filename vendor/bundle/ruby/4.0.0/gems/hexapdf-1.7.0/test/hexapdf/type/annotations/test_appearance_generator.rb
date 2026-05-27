# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'

describe HexaPDF::Type::Annotations::AppearanceGenerator do
  before do
    @doc = HexaPDF::Document.new
  end

  describe "create" do
    it "fails for unsupported annotation types" do
      annot = @doc.add({Type: :Annot, Subtype: :Unknown})
      error = assert_raises(HexaPDF::Error) do
        HexaPDF::Type::Annotations::AppearanceGenerator.new(annot).create_appearance
      end
      assert_match(/Unknown.*not yet supported/, error.message)
    end
  end

  describe "line" do
    before do
      @line = @doc.add({Type: :Annot, Subtype: :Line, L: [100, 100, 200, 100], C: [0]})
      @generator = HexaPDF::Type::Annotations::AppearanceGenerator.new(@line)
    end

    it "sets the print flag and unsets the hidden flag" do
      @line.flag(:hidden)
      @generator.create_appearance
      assert(@line.flagged?(:print))
      refute(@line.flagged?(:hidden))
    end

    it "creates a simple line" do
      @generator.create_appearance
      assert_equal([96, 96, 204, 104], @line[:Rect])
      assert_equal([96, 96, 204, 104], @line.appearance[:BBox])
      assert_operators(@line.appearance.stream,
                       [[:concatenate_matrix, [1.0, 0.0, -0.0, 1.0, 100, 100]],
                        [:move_to, [0, 0]],
                        [:line_to, [100.0, 0]],
                        [:stroke_path]])
    end

    it "creates a rotated line" do
      @line.line(100, 100, 50, 150)
      @generator.create_appearance
      assert_equal([46, 96, 104, 154], @line[:Rect])
      assert_operators(@line.appearance.stream,
                       [[:concatenate_matrix, [-0.707107, 0.707107, -0.707107, -0.707107, 100, 100]],
                        [:move_to, [0, 0]],
                        [:line_to, [70.710678, 0]],
                        [:stroke_path]])
    end

    describe "stroke color" do
      it "uses the specified border color for stroking operations" do
        @line.border_style(color: "red")
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [:set_device_rgb_stroking_color, [1, 0, 0]], range: 0)
      end

      it "works with a transparent border" do
        @line.border_style(color: :transparent, width: 1)
        @generator.create_appearance
        assert_operators(@line.appearance.stream, [:end_path], range: 3)
      end
    end

    it "uses the specified interior color for non-stroking operations" do
      @line.interior_color("red")
      @generator.create_appearance
      assert_operators(@line.appearance.stream,
                       [:set_device_rgb_non_stroking_color, [1, 0, 0]], range: 0)
    end

    it "sets the specified border line width" do
      @line.border_style(width: 2)
      @generator.create_appearance
      assert_operators(@line.appearance.stream,
                       [:set_line_width, [2]], range: 0)
    end

    it "sets the specified line dash pattern if it is an array" do
      @line.border_style(style: [5, 2])
      @generator.create_appearance
      assert_operators(@line.appearance.stream,
                       [:set_line_dash_pattern, [[5, 2], 0]], range: 0)
    end

    describe "leader lines" do
      it "works for positive leader line length values" do
        @line.leader_line_length(10)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:concatenate_matrix, [1.0, 0.0, -0.0, 1.0, 100, 100]],
                          [:move_to, [0, 0]],
                          [:line_to, [0, 10]],
                          [:move_to, [100, 0]],
                          [:line_to, [100, 10]],
                          [:move_to, [0, 10]],
                          [:line_to, [100.0, 10]],
                          [:stroke_path]])
      end

      it "works for negative leader line length values" do
        @line.leader_line_length(-10)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:concatenate_matrix, [1.0, 0.0, -0.0, 1.0, 100, 100]],
                          [:move_to, [0, 0]],
                          [:line_to, [0, -10]],
                          [:move_to, [100, 0]],
                          [:line_to, [100, -10]],
                          [:move_to, [0, -10]],
                          [:line_to, [100.0, -10]],
                          [:stroke_path]])
      end

      it "works when using an offset and a positive leader line length" do
        @line.leader_line_length(10)
        @line.leader_line_offset(5)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:concatenate_matrix, [1.0, 0.0, -0.0, 1.0, 100, 100]],
                          [:move_to, [0, 5]],
                          [:line_to, [0, 15]],
                          [:move_to, [100, 5]],
                          [:line_to, [100, 15]],
                          [:move_to, [0, 15]],
                          [:line_to, [100.0, 15]],
                          [:stroke_path]])
      end

      it "works when using an offset and a negative leader line length" do
        @line.leader_line_length(-10)
        @line.leader_line_offset(5)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:concatenate_matrix, [1.0, 0.0, -0.0, 1.0, 100, 100]],
                          [:move_to, [0, -5]],
                          [:line_to, [0, -15]],
                          [:move_to, [100, -5]],
                          [:line_to, [100, -15]],
                          [:move_to, [0, -15]],
                          [:line_to, [100.0, -15]],
                          [:stroke_path]])
      end

      it "works when using leader line extensions" do
        @line.leader_line_length(10)
        @line.leader_line_extension_length(5)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:concatenate_matrix, [1.0, 0.0, -0.0, 1.0, 100, 100]],
                          [:move_to, [0, 0]],
                          [:line_to, [0, 15]],
                          [:move_to, [100, 0]],
                          [:line_to, [100, 15]],
                          [:move_to, [0, 10]],
                          [:line_to, [100.0, 10]],
                          [:stroke_path]])
      end
    end

    describe "line ending styles" do
      before do
        @line.border_style(width: 2)
        @line.interior_color("red")
      end

      it "works correctly for a transparent border" do
        @line.line_ending_style(start_style: :square, end_style: :square)
        @line.border_style(color: :transparent)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:append_rectangle, [-3, -3, 6, 6]],
                          [:fill_path_non_zero],
                          [:append_rectangle, [97, -3, 6, 6]],
                          [:fill_path_non_zero]], range: 5..-1)
      end

      it "works for a square" do
        @line.line_ending_style(start_style: :square, end_style: :square)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:append_rectangle, [-6, -6, 12, 12]],
                          [:fill_and_stroke_path_non_zero],
                          [:append_rectangle, [94, -6, 12, 12]],
                          [:fill_and_stroke_path_non_zero]], range: 6..-1)
      end

      it "works for a circle" do
        @line.line_ending_style(start_style: :circle, end_style: :circle)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [6.0, 0.0]],
                          [:curve_to, [6.0, 2.140933, 4.854102, 4.125686, 3.0, 5.196152]],
                          [:curve_to, [1.145898, 6.266619, -1.145898, 6.266619, -3.0, 5.196152]],
                          [:curve_to, [-4.854102, 4.125686, -6.0, 2.140933, -6.0, 0.0]],
                          [:curve_to, [-6.0, -2.140933, -4.854102, -4.125686, -3.0, -5.196152]],
                          [:curve_to, [-1.145898, -6.266619, 1.145898, -6.266619, 3.0, -5.196152]],
                          [:curve_to, [4.854102, -4.125686, 6.0, -2.140933, 6.0, -0.0]],
                          [:close_subpath],
                          [:fill_and_stroke_path_non_zero],
                          [:move_to, [106.0, 0.0]],
                          [:curve_to, [106.0, 2.140933, 104.854102, 4.125686, 103.0, 5.196152]],
                          [:curve_to, [101.145898, 6.266619, 98.854102, 6.266619, 97.0, 5.196152]],
                          [:curve_to, [95.145898, 4.125686, 94.0, 2.140933, 94.0, 0.0]],
                          [:curve_to, [94.0, -2.140933, 95.145898, -4.125686, 97.0, -5.196152]],
                          [:curve_to, [98.854102, -6.266619, 101.145898, -6.266619, 103.0, -5.196152]],
                          [:curve_to, [104.854102, -4.125686, 106.0, -2.140933, 106.0, -0.0]],
                          [:close_subpath],
                          [:fill_and_stroke_path_non_zero]], range: 6..-1)
      end

      it "works for a diamond" do
        @line.line_ending_style(start_style: :diamond, end_style: :diamond)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [6, 0]],
                          [:line_to, [0, 6]],
                          [:line_to, [-6, 0]],
                          [:line_to, [0, -6]],
                          [:close_subpath],
                          [:fill_and_stroke_path_non_zero],
                          [:move_to, [106.0, 0]],
                          [:line_to, [100.0, 6]],
                          [:line_to, [94.0, 0]],
                          [:line_to, [100.0, -6]],
                          [:close_subpath],
                          [:fill_and_stroke_path_non_zero]], range: 6..-1)
      end

      it "works for open and closed as well as reversed open and closed arrows" do
        dx = 15.588457
        [:open_arrow, :closed_arrow, :ropen_arrow, :rclosed_arrow].each do |style|
          @line.line_ending_style(start_style: style, end_style: style)
          @generator.create_appearance
          used_dx = (style == :ropen_arrow || style == :rclosed_arrow ? -dx : dx)
          ops = [[:move_to, [used_dx, 9.0]],
                 [:line_to, [0, 0]],
                 [:line_to, [used_dx, -9.0]],
                 [:move_to, [100 - used_dx, -9.0]],
                 [:line_to, [100.0, 0]],
                 [:line_to, [100 - used_dx, 9.0]]]
          if style == :closed_arrow || style == :rclosed_arrow
            ops.insert(3, [:close_subpath], [:fill_and_stroke_path_non_zero])
            ops.insert(-1, [:close_subpath], [:fill_and_stroke_path_non_zero])
          else
            ops.insert(3, [:stroke_path])
            ops.insert(-1, [:stroke_path])
          end
          assert_operators(@line.appearance.stream, ops, range: 6..-1)
        end
      end

      it "works for butt" do
        @line.line_ending_style(start_style: :butt, end_style: :butt)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [0, 6]],
                          [:line_to, [0, -6]],
                          [:stroke_path],
                          [:move_to, [100.0, 6]],
                          [:line_to, [100.0, -6]],
                          [:stroke_path]], range: 6..-1)
      end

      it "works for slash" do
        @line.line_ending_style(start_style: :slash, end_style: :slash)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [3, 5.196152]],
                          [:line_to, [-3, -5.196152]],
                          [:stroke_path],
                          [:move_to, [103.0, 5.196152]],
                          [:line_to, [97.0, -5.196152]],
                          [:stroke_path]], range: 6..-1)
      end
    end

    describe "caption" do
      before do
        @line.captioned(true)
        @line.contents("Test")
      end

      it "adjusts the annotation's /Rect entry" do
        @line.contents("This is some eeeeextra long text")
        @generator.create_appearance
        assert_equal([80.2225, 91.83749999999999, 219.7775, 108.1625], @line[:Rect])
      end

      it "puts the caption inline" do
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [0, 0]],
                          [:line_to, [40.2475, 0]],
                          [:move_to, [59.7525, 0]],
                          [:line_to, [100, 0]],
                          [:stroke_path],
                          [:save_graphics_state],
                          [:set_font_and_size, [:F1, 9]],
                          [:begin_text],
                          [:move_text, [41.2475, -2.2995]],
                          [:show_text, ["Test"]],
                          [:end_text]], range: 1..-2)
      end

      it "puts the caption inline with an offset" do
        @line.caption_offset(20, 5)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [0, 0]],
                          [:line_to, [60.2475, 0]],
                          [:move_to, [79.7525, 0]],
                          [:line_to, [100, 0]],
                          [:stroke_path],
                          [:save_graphics_state],
                          [:set_font_and_size, [:F1, 9]],
                          [:begin_text],
                          [:move_text, [61.2475, 2.7005]],
                          [:show_text, ["Test"]],
                          [:end_text]], range: 1..-2)
      end

      it "handles too long inline captions" do
        @line.contents('This inline text is so long that no line is shown')
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [0, 0]],
                          [:line_to, [0, 0]],
                          [:move_to, [100, 0]],
                          [:line_to, [100, 0]],
                          [:stroke_path],
                          [:save_graphics_state],
                          [:set_font_and_size, [:F1, 9]],
                          [:begin_text],
                          [:move_text, [-41.0395, -2.2995]],
                          [:show_text, ["This inline text is so long that no line is shown"]],
                          [:end_text]], range: 1..-2)
      end

      it "puts the caption on top of the line" do
        @line.caption_position(:top)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [0, 0]],
                          [:line_to, [100, 0]],
                          [:stroke_path],
                          [:save_graphics_state],
                          [:set_font_and_size, [:F1, 9]],
                          [:begin_text],
                          [:move_text, [41.2475, 3.863]],
                          [:show_text, ["Test"]],
                          [:end_text]], range: 1..-2)
      end

      it "puts the caption on top of the line" do
        @line.caption_position(:top)
        @line.caption_offset(-20, -5)
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [0, 0]],
                          [:line_to, [100, 0]],
                          [:stroke_path],
                          [:save_graphics_state],
                          [:set_font_and_size, [:F1, 9]],
                          [:begin_text],
                          [:move_text, [21.2475, -1.137]],
                          [:show_text, ["Test"]],
                          [:end_text]], range: 1..-2)
      end

      it "handles text with line breaks" do
        @line.contents("This inline text\ris long")
        @generator.create_appearance
        assert_operators(@line.appearance.stream,
                         [[:move_to, [0, 0]],
                          [:line_to, [20.2405, 0]],
                          [:move_to, [79.7595, 0]],
                          [:line_to, [100, 0]],
                          [:stroke_path],
                          [:save_graphics_state],
                          [:set_leading, [10.40625]],
                          [:set_font_and_size, [:F1, 9]],
                          [:begin_text],
                          [:move_text, [21.2405, 2.903625]],
                          [:show_text, ["This inline text"]],
                          [:move_text_next_line],
                          [:show_text, ["is long"]],
                          [:end_text]], range: 1..-2)
      end
    end
  end

  describe "square/circle" do
    before do
      @square = @doc.add({Type: :Annot, Subtype: :Square, Rect: [100, 100, 200, 150], C: [0],
                          BS: {W: 2}})
      @generator = HexaPDF::Type::Annotations::AppearanceGenerator.new(@square)
    end

    it "sets the print flag and unsets the hidden flag" do
      @square.flag(:hidden)
      @generator.create_appearance
      assert(@square.flagged?(:print))
      refute(@square.flagged?(:hidden))
    end

    it "creates the /RD entry if it doesn't exist and adjusts the /Rect" do
      @generator.create_appearance
      assert_equal([99, 99, 201, 151], @square[:Rect])
      assert_equal([0, 0, 102, 52], @square.appearance[:BBox])
      assert_operators(@square.appearance.stream,
                       [[:set_line_width, [2]],
                        [:append_rectangle, [1, 1, 100, 50]],
                        [:stroke_path]])
    end

    it "uses an existing /RD entry" do
      @square[:RD] = [2, 4, 6, 8]
      @generator.create_appearance
      assert_equal([100, 100, 200, 150], @square[:Rect])
      assert_equal([0, 0, 100, 50], @square.appearance[:BBox])
      assert_operators(@square.appearance.stream,
                       [[:set_line_width, [2]],
                        [:append_rectangle, [3, 9, 90, 36]],
                        [:stroke_path]])
    end

    it "can apply just a fill color without a stroke color" do
      @square.delete(:C)
      @square.interior_color(255, 0, 0)
      @generator.create_appearance
      assert_operators(@square.appearance.stream,
                       [[:set_device_rgb_non_stroking_color, [1, 0, 0]],
                        [:set_line_width, [2]],
                        [:append_rectangle, [1, 1, 100, 50]],
                        [:fill_path_non_zero]])
    end

    it "applies all set styling options" do
      @square.border_style(color: [255, 0, 0], width: 10, style: [2, 1])
      @square.interior_color(0, 255, 0)
      @square.opacity(fill_alpha: 0.5, stroke_alpha: 0.5)
      @generator.create_appearance
      assert_operators(@square.appearance.stream,
                       [[:set_graphics_state_parameters, [:GS1]],
                        [:set_device_rgb_stroking_color, [1, 0, 0]],
                        [:set_device_rgb_non_stroking_color, [0, 1, 0]],
                        [:set_line_width, [10]],
                        [:set_line_dash_pattern, [[2, 1], 0]],
                        [:append_rectangle, [5, 5, 100, 50]],
                        [:fill_and_stroke_path_non_zero]])
    end

    it "doesn't draw anything if neither stroke nor fill color is set" do
      @square.delete(:C)
      @generator.create_appearance
      assert_operators(@square.appearance.stream, [])
    end

    it "draws an ellipse" do
      @square[:Subtype] = :Circle
      @generator.create_appearance
      assert_operators(@square.appearance.stream,
                       [[:set_line_width, [2]],
                        [:move_to, [101.0, 26.0]],
                        [:curve_to, [101.0, 34.920552, 91.45085, 43.190359, 76.0, 47.650635]],
                        [:curve_to, [60.54915, 52.110911, 41.45085, 52.110911, 26.0, 47.650635]],
                        [:curve_to, [10.54915, 43.190359, 1.0, 34.920552, 1.0, 26.0]],
                        [:curve_to, [1.0, 17.079448, 10.54915, 8.809641, 26.0, 4.349365]],
                        [:curve_to, [41.45085, -0.110911, 60.54915, -0.110911, 76.0, 4.349365]],
                        [:curve_to, [91.45085, 8.809641, 101.0, 17.079448, 101.0, 26.0]],
                        [:close_subpath],
                        [:stroke_path]])
    end
  end

  describe "polygon/polyline" do
    before do
      @polyline = @doc.add({Type: :Annot, Subtype: :PolyLine, C: [0],
                            Vertices: [100, 100, 200, 150, 210, 80]})
      @generator = HexaPDF::Type::Annotations::AppearanceGenerator.new(@polyline)
    end

    it "sets the print flag and unsets the hidden flag" do
      @polyline.flag(:hidden)
      @generator.create_appearance
      assert(@polyline.flagged?(:print))
      refute(@polyline.flagged?(:hidden))
    end

    it "creates a simple polyline" do
      @generator.create_appearance
      assert_equal([96, 76, 214, 154], @polyline[:Rect])
      assert_equal([96, 76, 214, 154], @polyline.appearance[:BBox])
      assert_operators(@polyline.appearance.stream,
                       [[:move_to, [100, 100]],
                        [:line_to, [200, 150]],
                        [:line_to, [210, 80]],
                        [:stroke_path]])
    end

    it "creates a simple polygon" do
      @polyline[:Subtype] = :Polygon
      @generator.create_appearance
      assert_operators(@polyline.appearance.stream,
                       [[:move_to, [100, 100]],
                        [:line_to, [200, 150]],
                        [:line_to, [210, 80]],
                        [:close_subpath],
                        [:stroke_path]])
    end

    describe "stroke color" do
      it "uses the specified border color for stroking operations" do
        @polyline.border_style(color: "red")
        @generator.create_appearance
        assert_operators(@polyline.appearance.stream,
                         [:set_device_rgb_stroking_color, [1, 0, 0]], range: 0)
        assert_operators(@polyline.appearance.stream,
                         [:stroke_path], range: 4)
      end

      it "works with a transparent border" do
        @polyline.border_style(color: :transparent)
        @generator.create_appearance
        assert_operators(@polyline.appearance.stream, [:end_path], range: 3)
      end
    end

    describe "interior color" do
      it "uses the specified interior color for non-stroking operations" do
        @polyline[:Subtype] = :Polygon
        @polyline.border_style(color: :transparent)
        @polyline.interior_color("red")
        @generator.create_appearance
        assert_operators(@polyline.appearance.stream,
                         [:set_device_rgb_non_stroking_color, [1, 0, 0]], range: 0)
        assert_operators(@polyline.appearance.stream,
                         [:fill_path_non_zero], range: 5)
      end

      it "works together with the stroke color" do
        @polyline[:Subtype] = :Polygon
        @polyline.interior_color("red")
        @generator.create_appearance
        assert_operators(@polyline.appearance.stream,
                         [:set_device_rgb_non_stroking_color, [1, 0, 0]], range: 0)
        assert_operators(@polyline.appearance.stream,
                         [:fill_and_stroke_path_non_zero], range: 5)
      end

      it "works if neither interior nor border color is used" do
        @polyline[:Subtype] = :Polygon
        @polyline.interior_color(:transparent)
        @polyline.border_style(color: :transparent)
        @generator.create_appearance
        assert_operators(@polyline.appearance.stream,
                         [:end_path], range: 4)
      end
    end

    it "sets the specified border line width" do
      @polyline.border_style(width: 4)
      @generator.create_appearance
      assert_operators(@polyline.appearance.stream,
                       [:set_line_width, [4]], range: 0)
    end

    it "sets the specified line dash pattern if it is an array" do
      @polyline.border_style(style: [5, 2])
      @generator.create_appearance
      assert_operators(@polyline.appearance.stream,
                       [:set_line_dash_pattern, [[5, 2], 0]], range: 0)
    end

    it "sets the specified opacity" do
      @polyline.opacity(fill_alpha: 0.5, stroke_alpha: 0.5)
      @generator.create_appearance
      assert_operators(@polyline.appearance.stream,
                       [:set_graphics_state_parameters, [:GS1]], range: 0)
    end

    it "draws the specified line ending style" do
      @polyline.line_ending_style(start_style: :open_arrow, end_style: :rclosed_arrow)
      @polyline.border_style(width: 2)
      @polyline.interior_color("red")
      @generator.create_appearance
      assert_equal([86, 52, 238, 158], @polyline[:Rect])
      assert_equal([86, 52, 238, 158], @polyline.appearance[:BBox])
      assert_operators(@polyline.appearance.stream,
                       [[:move_to, [109.917818, 115.021215]],
                        [:line_to, [100, 100]],
                        [:line_to, [117.967662, 98.921525]],
                        [:stroke_path],
                        [:move_to, [221.114086, 94.158993]],
                        [:line_to, [210, 80]],
                        [:line_to, [203.294995, 96.704578]],
                        [:close_subpath],
                        [:fill_and_stroke_path_non_zero]], range: 6..-1)
    end
  end
end
