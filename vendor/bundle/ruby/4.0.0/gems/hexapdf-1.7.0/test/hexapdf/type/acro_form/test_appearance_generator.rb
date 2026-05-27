# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/appearance_generator'

describe HexaPDF::Type::AcroForm::AppearanceGenerator do
  before do
    @doc = HexaPDF::Document.new
    @page = @doc.pages.add
    @form = @doc.acro_form(create: true)
  end

  describe "create_appearances" do
    before do
      @field = @doc.add({FT: :Btn}, type: :XXAcroFormField, subtype: :Btn)
      @widget = @doc.wrap({Parent: @field, Type: :Annot, Subtype: :Widget})
      @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
    end

    it "fails for unsupported field types" do
      @field[:FT] = :Unknown
      assert_raises(HexaPDF::Error) { @generator.create_appearances }
    end
  end

  describe "background color and border" do
    before do
      @field = @doc.add({FT: :Btn}, type: :XXAcroFormField, subtype: :Btn)
      @widget = @field.create_widget(@page, defaults: false, Rect: [0, 0, 10, 20])
      @xform = @doc.add({Type: :XObject, Subtype: :Form, BBox: @widget[:Rect]})
      @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
    end

    def execute(circular = false)
      @generator.send(:apply_background_and_border, @widget.border_style, @xform.canvas,
                      circular: circular)
    end

    it "applies no background color or border if none is set" do
      execute
      assert_operators(@xform.stream, [])
    end

    it "applies a background color if one set" do
      @widget.background_color(0.5)
      execute
      execute(true)
      assert_operators(@xform.stream,
                       [[:save_graphics_state],
                        [:set_device_gray_non_stroking_color, [0.5]],
                        [:append_rectangle, [0, 0, 10, 20]],
                        [:fill_path_non_zero], [:restore_graphics_state],

                        [:save_graphics_state],
                        [:set_device_gray_non_stroking_color, [0.5]],
                        [:move_to, [10.0, 10.0]],
                        [:curve_to, [10.0, 11.78411, 9.045085, 13.438072, 7.5, 14.330127]],
                        [:curve_to, [5.954915, 15.222182, 4.045085, 15.222182, 2.5, 14.330127]],
                        [:curve_to, [0.954915, 13.438072, 0.0, 11.78411, 0.0, 10.0]],
                        [:curve_to, [-0.0, 8.21589, 0.954915, 6.561928, 2.5, 5.669873]],
                        [:curve_to, [4.045085, 4.777818, 5.954915, 4.777818, 7.5, 5.669873]],
                        [:curve_to, [9.045085, 6.561928, 10.0, 8.21589, 10.0, 10.0]],
                        [:close_subpath], [:fill_path_non_zero], [:restore_graphics_state]])
    end

    it "sets the border color and width correctly" do
      @widget.border_style(color: 0.5, width: 4)
      execute
      execute(true)
      assert_operators(@xform.stream,
                       [[:save_graphics_state],
                        [:set_device_gray_stroking_color, [0.5]],
                        [:set_line_width, [4]],
                        [:append_rectangle, [2, 2, 6, 16]],
                        [:stroke_path], [:restore_graphics_state],

                        [:save_graphics_state],
                        [:set_device_gray_stroking_color, [0.5]],
                        [:set_line_width, [4]],
                        [:move_to, [8.0, 10.0]],
                        [:curve_to, [8.0, 11.070466, 7.427051, 12.062843, 6.5, 12.598076]],
                        [:curve_to, [5.572949, 13.133309, 4.427051, 13.133309, 3.5, 12.598076]],
                        [:curve_to, [2.572949, 12.062843, 2.0, 11.070466, 2.0, 10.0]],
                        [:curve_to, [2.0, 8.929534, 2.572949, 7.937157, 3.5, 7.401924]],
                        [:curve_to, [4.427051, 6.866691, 5.572949, 6.866691, 6.5, 7.401924]],
                        [:curve_to, [7.427051, 7.937157, 8.0, 8.929534, 8.0, 10.0]],
                        [:close_subpath], [:stroke_path], [:restore_graphics_state]])
    end

    it "handles the case of an underlined border" do
      @widget.border_style(style: :underlined, width: 2)
      execute
      execute(true)
      assert_operators(@xform.stream,
                       [[:save_graphics_state],
                        [:set_line_width, [2]],
                        [:move_to, [1, 1]], [:line_to, [9.0, 1]],
                        [:stroke_path], [:restore_graphics_state],

                        [:save_graphics_state],
                        [:set_line_width, [2]],
                        [:move_to, [1.0, 10.0]],
                        [:curve_to, [1.0, 8.572712, 1.763932, 7.249543, 3.0, 6.535898]],
                        [:curve_to, [4.236068, 5.822254, 5.763932, 5.822254, 7.0, 6.535898]],
                        [:curve_to, [8.236068, 7.249543, 9.0, 8.572712, 9.0, 10.0]],
                        [:stroke_path], [:restore_graphics_state]])
    end

    it "handles the special case of a comb field" do
      @field = @doc.add({FT: :Tx, MaxLen: 4}, type: :XXAcroFormField, subtype: :Tx)
      @field.initialize_as_comb_text_field
      @widget = @field.create_widget(@page, Rect: [0, 0, 10, 20])
      @xform = @doc.add({Type: :XObject, Subtype: :Form, BBox: @widget[:Rect]})
      @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
      @widget.border_style(width: 2)
      execute
      assert_operators(@xform.stream,
                       [[:save_graphics_state],
                        [:set_line_width, [2]],
                        [:append_rectangle, [1, 1, 8, 18]],
                        [:move_to, [2.5, 2]], [:line_to, [2.5, 20.0]],
                        [:move_to, [5.0, 2]], [:line_to, [5.0, 20.0]],
                        [:move_to, [7.5, 2]], [:line_to, [7.5, 20.0]],
                        [:stroke_path], [:restore_graphics_state]])
    end
  end

  describe "draw_marker" do
    before do
      @field = @doc.add({FT: :Btn}, type: :XXAcroFormField, subtype: :Btn)
      @widget = @field.create_widget(@page, defaults: false, Rect: [0, 0, 10, 20])
      @xform = @doc.add({Type: :XObject, Subtype: :Form, BBox: @widget[:Rect]})
      @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
    end

    def execute
      @generator.send(:draw_marker, @xform.canvas, @widget[:Rect].width, @widget[:Rect].height,
                      @widget.border_style.width, @widget.marker_style)
    end

    it "handles the marker :circle specially for radio button widgets" do
      @field.initialize_as_radio_button
      @widget.marker_style(style: :circle, color: 0.5)
      execute
      assert_operators(@xform.stream,
                       [[:set_device_gray_non_stroking_color, [0.5]],
                        [:move_to, [7.0, 10.0]],
                        [:curve_to, [7.0, 10.713644, 6.618034, 11.375229, 6.0, 11.732051]],
                        [:curve_to, [5.381966, 12.088873, 4.618034, 12.088873, 4.0, 11.732051]],
                        [:curve_to, [3.381966, 11.375229, 3.0, 10.713644, 3.0, 10.0]],
                        [:curve_to, [3.0, 9.286356, 3.381966, 8.624771, 4.0, 8.267949]],
                        [:curve_to, [4.618034, 7.911127, 5.381966, 7.911127, 6.0, 8.267949]],
                        [:curve_to, [6.618034, 8.624771, 7.0, 9.286356, 7.0, 10.0]],
                        [:close_subpath],
                        [:fill_path_non_zero]])
    end

    it "handles the marker :cross specially" do
      @widget.marker_style(style: :cross, color: 0.5)
      execute
      assert_operators(@xform.stream,
                       [[:set_device_gray_stroking_color, [0.5]],
                        [:move_to, [1, 1]], [:line_to, [9, 19]],
                        [:move_to, [1, 19]], [:line_to, [9, 1]],
                        [:stroke_path]])
    end

    describe "handles the normal markers by drawing them using the ZapfDingbats font" do
      it "works with font auto-sizing" do
        @widget.marker_style(style: :check, color: 0.5, size: 0)
        execute
        assert_operators(@xform.stream,
                         [[:set_font_and_size, [:F1, 8]],
                          [:set_device_gray_non_stroking_color, [0.5]],
                          [:begin_text],
                          [:set_text_matrix, [1, 0, 0, 1, 1.616, 7.236]],
                          [:show_text, ["4"]],
                          [:end_text]])
      end

      it "works with a fixed font size" do
        @widget.marker_style(style: :check, color: 0.5, size: 5)
        execute
        assert_operators(@xform.stream,
                         [[:set_font_and_size, [:F1, 5]],
                          [:set_device_gray_non_stroking_color, [0.5]],
                          [:begin_text],
                          [:set_text_matrix, [1, 0, 0, 1, 2.885, 8.2725]],
                          [:show_text, ["4"]],
                          [:end_text]])
      end

      it "draws the default marker if an empty string is specified as marker" do
        @widget.marker_style(style: '', color: 0.5, size: 5)
        execute
        assert_operators(@xform.stream,
                         [[:set_font_and_size, [:F1, 5]],
                          [:set_device_gray_non_stroking_color, [0.5]],
                          [:begin_text],
                          [:set_text_matrix, [1, 0, 0, 1, 2.885, 8.2725]],
                          [:show_text, ["4"]],
                          [:end_text]])
      end
    end
  end

  describe "button fields" do
    before do
      @field = @doc.add({FT: :Btn}, type: :XXAcroFormField, subtype: :Btn)
    end

    describe "check box" do
      before do
        @widget = @field.create_widget(@page, Rect: [0, 0, 0, 0])
        @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
        @field.field_value = :Off
      end

      it "updates the widgets' /AS entry to point to the selected appearance" do
        @generator.create_appearances
        assert_equal(:Off, @widget[:AS])

        @field.field_value = :Yes
        @generator.create_appearances
        assert_equal(:Yes, @widget[:AS])

        @field.delete(:V)
        @generator.create_appearances
        assert_equal(:Off, @widget[:AS])
      end

      it "set the print flag on the widgets" do
        @generator.create_appearances
        assert(@widget.flagged?(:print))
      end

      it "removes the hidden flag on the widgets" do
        @widget.flag(:hidden)
        @generator.create_appearances
        refute(@widget.flagged?(:hidden))
      end

      it "adjusts the /Rect if width is zero" do
        @generator.create_appearances
        assert_equal(12, @widget[:Rect].width)
      end

      it "adjusts the /Rect if height is zero" do
        @generator.create_appearances
        assert_equal(12, @widget[:Rect].height)
      end

      describe "takes the rotation into account" do
        def check_rotation(angle, width, height, matrix)
          @widget[:MK] = {R: angle}
          @field[:V] = :Yes
          @generator.create_appearances
          form = @widget[:AP][:N][@widget[:AS]]
          assert_equal([0, 0, width, height], form[:BBox].value)
          assert_equal(matrix, form[:Matrix].value)
        end

        it "works for 0 degrees" do
          check_rotation(-360, @widget[:Rect].width, @widget[:Rect].height, [1, 0, 0, 1, 0, 0])
        end

        it "works for 90 degrees" do
          check_rotation(450, @widget[:Rect].height, @widget[:Rect].width, [0, 1, -1, 0, 0, 0])
        end

        it "works for 180 degrees" do
          check_rotation(180, @widget[:Rect].width, @widget[:Rect].height, [0, -1, -1, 0, 0, 0])
        end

        it "works for 270 degrees" do
          check_rotation(-90, @widget[:Rect].height, @widget[:Rect].width, [0, -1, 1, 0, 0, 0])
        end
      end

      it "creates the needed appearance dictionary for the normal appearance" do
        @widget[:AP][:N] = 5
        @generator.create_appearances
        assert_equal(:XObject, @widget[:AP][:N][:Off].type)
        assert_equal(:XObject, @widget[:AP][:N][:Yes].type)

        @field[:V] = :Other
        @widget[:AP][:N] = @doc.wrap({Type: :XObject, Subtype: :Form})
        @generator.create_appearances
        assert_equal(:XObject, @widget[:AP][:N][:Off].type)
        assert_equal(:XObject, @widget[:AP][:N][:Other].type)
      end

      it "uses the field's value or :Yes for the on state if the appearance dictionary doesn't contain a name for it" do
        @widget[:AP][:N].delete(:Yes)
        @generator.create_appearances
        assert_equal(:XObject, @widget[:AP][:N][:Yes].type)

        @widget[:AP][:N].delete(:Yes)
        @field[:V] = nil
        @generator.create_appearances
        assert_equal(:XObject, @widget[:AP][:N][:Yes].type)

        @widget[:AP][:N].delete(:Yes)
        @field[:V] = "other"   # some PDFs use a string instead of the correct symbol
        @generator.create_appearances
        assert_equal(:XObject, @widget[:AP][:N][:other].type)
      end

      it "creates the needed appearance streams" do
        @widget[:AP][:N].delete(:Off)
        @generator.create_appearances
        assert_equal(:XObject, @widget[:AP][:N][:Off].type)
        assert_equal(:XObject, @widget[:AP][:N][:Yes].type)
      end

      it "creates the /Off appearance stream" do
        @generator.create_appearances
        assert_operators(@widget[:AP][:N][:Off].stream,
                         [[:save_graphics_state],
                          [:set_device_gray_non_stroking_color, [1.0]],
                          [:append_rectangle, [0, 0, 12, 12]],
                          [:fill_path_non_zero],
                          [:append_rectangle, [0.5, 0.5, 11, 11]],
                          [:stroke_path], [:restore_graphics_state]])
      end

      it "creates the /Yes appearance stream" do
        @generator.create_appearances
        assert_operators(@widget[:AP][:N][:Yes].stream,
                         [[:save_graphics_state],
                          [:set_device_gray_non_stroking_color, [1.0]],
                          [:append_rectangle, [0, 0, 12, 12]],
                          [:fill_path_non_zero],
                          [:append_rectangle, [0.5, 0.5, 11, 11]],
                          [:stroke_path], [:restore_graphics_state],

                          [:save_graphics_state],
                          [:set_font_and_size, [:F1, 10]],
                          [:begin_text],
                          [:set_text_matrix, [1, 0, 0, 1, 1.77, 2.545]],
                          [:show_text, ["4"]],
                          [:end_text],
                          [:restore_graphics_state]])
      end
    end

    describe "radio button" do
      before do
        @field.initialize_as_radio_button
        @widget = @field.create_widget(@page, Rect: [0, 0, 0, 0], value: :radio)
        @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
      end

      it "updates the widgets' /AS entry to point to the selected appearance" do
        @field.field_value = :radio
        @generator.create_appearances
        assert_equal(@field[:V], @widget[:AS])

        @field.create_widget(@page, value: :other)
        @field.field_value = :other
        @generator.create_appearances
        assert_equal(:Off, @widget[:AS])
      end

      it "creates the needed appearance streams" do
        @generator.create_appearances
        assert_equal(:XObject, @widget[:AP][:N][:Off].type)
        assert_equal(:XObject, @widget[:AP][:N][:radio].type)
      end
    end

    describe "push buttons" do
      before do
        @field.initialize_as_push_button
        @widget = @field.create_widget(@page, Rect: [0, 0, 100, 50])
        @widget.marker_style(style: 'Test')
        @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
      end

      it "set the print flag on the widgets" do
        @generator.create_appearances
        assert(@widget.flagged?(:print))
      end

      it "removes the hidden flag on the widgets" do
        @widget.flag(:hidden)
        @generator.create_appearances
        refute(@widget.flagged?(:hidden))
      end

      it "adds an appropriate form XObject" do
        @generator.create_appearances
        form = @widget[:AP][:N]
        assert_equal(:XObject, form.type)
        assert_equal(:Form, form[:Subtype])
        assert_equal([0, 0, 100, 50], form[:BBox])
        assert_equal(@doc.acro_form.default_resources[:Font][:F1], form[:Resources][:Font][:F1])
      end

      it "re-uses the existing form XObject" do
        @generator.create_appearances
        form = @widget[:AP][:N]
        form[:key] = :value
        form.delete(:Subtype)
        @widget[:AP][:N] = @doc.wrap(form, type: HexaPDF::Dictionary)

        @generator.create_appearances
        assert_equal(form, @widget[:AP][:N])
        refute(form.key?(:key))
      end

      describe "takes the rotation into account" do
        def check_rotation(angle, width, height, matrix)
          @widget[:MK][:R] = angle
          @generator.create_appearances
          form = @widget[:AP][:N]
          assert_equal([0, 0, width, height], form[:BBox].value)
          assert_equal(matrix, form[:Matrix].value)
        end

        it "works for 0 degrees" do
          check_rotation(-360, @widget[:Rect].width, @widget[:Rect].height, [1, 0, 0, 1, 0, 0])
        end

        it "works for 90 degrees" do
          check_rotation(450, @widget[:Rect].height, @widget[:Rect].width, [0, 1, -1, 0, 0, 0])
        end

        it "works for 180 degrees" do
          check_rotation(180, @widget[:Rect].width, @widget[:Rect].height, [0, -1, -1, 0, 0, 0])
        end

        it "works for 270 degrees" do
          check_rotation(-90, @widget[:Rect].height, @widget[:Rect].width, [0, -1, 1, 0, 0, 0])
        end
      end

      it "adds the button title in the center" do
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [[:save_graphics_state],
                          [:set_device_gray_non_stroking_color, [0.5]],
                          [:append_rectangle, [0, 0, 100, 50]],
                          [:fill_path_non_zero],
                          [:append_rectangle, [0.5, 0.5, 99.0, 49.0]],
                          [:stroke_path],
                          [:restore_graphics_state],
                          [:save_graphics_state],
                          [:set_font_and_size, [:F1, 9]],
                          [:begin_text],
                          [:move_text, [41.2475, 22.7005]],
                          [:show_text, ["Test"]],
                          [:end_text],
                          [:restore_graphics_state]],
                         )
      end
    end
  end

  describe "text fields" do
    before do
      @form.set_default_appearance_string
      @field = @doc.add({FT: :Tx}, type: :XXAcroFormField, subtype: :Tx)
      @widget = @field.create_widget(@page, Rect: [0, 0, 0, 0])
      @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
    end

    it "updates the widgets to use the :N appearance stream" do
      @generator.create_appearances
      assert_equal(:N, @widget[:AS])
    end

    it "set the print flag on the widgets" do
      @generator.create_appearances
      assert(@widget.flagged?(:print))
    end

    it "removes the hidden flag on the widgets" do
      @widget.flag(:hidden)
      @generator.create_appearances
      refute(@widget.flagged?(:hidden))
    end

    describe "it adjusts the :Rect when necessary" do
      before do
        @widget.border_style(width: 3)
      end

      it "uses a default width if the width is zero" do
        @generator.create_appearances
        assert_equal(@doc.config['acro_form.text_field.default_width'], @widget[:Rect].width)
      end

      it "uses the font size of the /DA if non-zero as basis for the height if it is zero" do
        @field.set_default_appearance_string(font_size: 10)
        @generator.create_appearances
        assert_equal(15.25, @widget[:Rect].height)
      end

      it "uses a default font size as basis for the height if it and the set font size are zero" do
        assert_equal(0, @field.parse_default_appearance_string[1])
        @generator.create_appearances
        assert_equal(15.25, @widget[:Rect].height)
      end
    end

    it "adds an appropriate form XObject" do
      @generator.create_appearances
      form = @widget[:AP][:N]
      assert_equal(:XObject, form.type)
      assert_equal(:Form, form[:Subtype])
      assert_equal([0, 0, @widget[:Rect].width, @widget[:Rect].height], form[:BBox])
      assert_equal(@doc.acro_form.default_resources[:Font][:F1], form[:Resources][:Font][:F1])
    end

    it "re-uses the existing form XObject" do
      @field[:V] = 'test'
      @generator.create_appearances
      form = @widget[:AP][:N]
      form[:key] = :value
      form.delete(:Subtype)
      @widget[:AP][:N] = @doc.wrap(form, type: HexaPDF::Dictionary)

      @field[:V] = 'test1'
      @generator.create_appearances
      assert_equal(form, @widget[:AP][:N])
      refute(form.key?(:key))
      assert_match(/test1/, form.contents)

      form.delete(:Type)
      @widget[:AP][:N] = @doc.wrap(form, type: HexaPDF::Type::Annotation)
      @field[:V] = 'test2'
      @generator.create_appearances
      assert_match(/test2/, form.contents)
    end

    describe "takes the rotation into account" do
      before do
        @widget[:Rect] = [0, 0, 100, 20]
      end

      def check_rotation(angle, width, height, matrix)
        @widget[:MK] = {R: angle}
        @field[:V] = 'test'
        @generator.create_appearances
        form = @widget[:AP][:N]
        assert_equal([0, 0, width, height], form[:BBox].value)
        assert_equal(matrix, form[:Matrix].value)
      end

      it "works for 0 degrees" do
        check_rotation(-360, @widget[:Rect].width, @widget[:Rect].height, [1, 0, 0, 1, 0, 0])
      end

      it "works for 90 degrees" do
        check_rotation(450, @widget[:Rect].height, @widget[:Rect].width, [0, 1, -1, 0, 0, 0])
      end

      it "works for 180 degrees" do
        check_rotation(180, @widget[:Rect].width, @widget[:Rect].height, [0, -1, -1, 0, 0, 0])
      end

      it "works for 270 degrees" do
        check_rotation(-90, @widget[:Rect].height, @widget[:Rect].width, [0, -1, 1, 0, 0, 0])
      end
    end

    describe "font size calculation" do
      before do
        @widget[:Rect].height = 20
        @widget[:Rect].width = 100
        @field[:V] = ''
      end

      it "uses the non-zero font size" do
        @field.set_default_appearance_string(font_size: 10)
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [:set_font_and_size, [:F1, 10]],
                         range: 5)
      end

      it "calculates the font size based on the rectangle height and border width" do
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [:set_font_and_size, [:F1, 13.235294]],
                         range: 5)
        @widget.border_style(width: 2, color: :transparent)
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [:set_font_and_size, [:F1, 11.764706]],
                         range: 5)
      end

      it "shrinks the font size if necessary to fit the rectangle width" do
        @field[:V] = "This is some arbitrary, long text"
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [:set_font_and_size, [:F1, 6.909955]],
                         range: 5)
      end

      it " in case of mulitline auto-sizing" do
        @field.initialize_as_multiline_text_field
        @field[:V] = 'a'
        @field.set_default_appearance_string(font_size: 0)
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [:set_font_and_size, [:F1, 12]],
                         range: 6)
      end
    end

    describe "single line text fields" do
      describe "quadding e.g. text alignment" do
        before do
          @field[:V] = 'Test'
          @field.set_default_appearance_string(font_size: 10)
          @widget[:Rect].height = 20
        end

        it "works for left aligned text" do
          @field.text_alignment(:left)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [2, 6.41]],
                           range: 7)
        end

        it "works for right aligned text" do
          @field.text_alignment(:right)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [78.55, 6.41]],
                           range: 7)
        end

        it "works for center aligned text" do
          @field.text_alignment(:center)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [40.275, 6.41]],
                           range: 7)
        end

        it "falls back to the cap height in the font descriptor for vertical alignment" do
          font_metrics = @form.default_resources.font(:F1).font_wrapper.wrapped_font.metrics
          cap_height = font_metrics.cap_height
          font_metrics.cap_height = nil

          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [2, 6.41]],
                           range: 7)
        ensure
          font_metrics.cap_height = cap_height
        end

        it "vertically aligns to the font descender if the text is too high" do
          @widget[:Rect].height = 5
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [2, 3.07]],
                           range: 7)
        end
      end

      it "applies JavaScript format actions" do
        @field[:V] = '1234567.898765'
        @field[:AA] = {F: {S: :JavaScript, JS: 'AFNumber_Format(0, 2, 0, 0, "E", false);'}}
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream, [:show_text, ["1.234.568E"]], range: 9)
      end

      it "creates the /N appearance stream according to the set string" do
        @doc.config['font.on_invalid_glyph'] = lambda do |codepoint, _|
          [@doc.fonts.add('ZapfDingbats').decode_codepoint(codepoint)]
        end
        @field.set_default_appearance_string(font_color: "red")
        @field[:V] = 'Te ✂ xt'
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [[:begin_marked_content, [:Tx]],
                          [:save_graphics_state],
                          [:append_rectangle, [1, 1, 98, 9.25]],
                          [:clip_path_non_zero],
                          [:end_path],
                          [:set_font_and_size, [:F1, 10]],
                          [:set_device_rgb_non_stroking_color, [1.0, 0.0, 0.0]],
                          [:begin_text],
                          [:move_text, [2, 2.035]],
                          [:show_text, ["Te "]],
                          [:set_font_and_size, [:F2, 10]],
                          [:move_text, [14.45, 0]],
                          [:show_text, ["\""]],
                          [:set_font_and_size, [:F1, 10]],
                          [:move_text, [9.61, 0]],
                          [:show_text, [" xt"]],
                          [:end_text],
                          [:restore_graphics_state],
                          [:end_marked_content]])
      end
    end

    describe "multiline text fields" do
      before do
        @field.set_default_appearance_string(font_size: 10)
        @field.initialize_as_multiline_text_field
        @widget[:Rect].height = 30
        @widget[:Rect].width = 100
      end

      describe "quadding e.g. text alignment" do
        before do
          @field[:V] = "Test\nValue"
        end

        it "works for left aligned text" do
          @field.text_alignment(:left)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [2, 16.195]],
                           range: 9)
        end

        it "works for right aligned text" do
          @field.text_alignment(:right)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [78.55, 16.195]],
                           range: 9)
        end

        it "works for center aligned text" do
          @field.text_alignment(:center)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [40.275, 16.195]],
                           range: 9)
        end
      end

      it "creates the /N appearance stream according to the set string" do
        @field[:V] = "Test\nValue"
        @field.set_default_appearance_string(font_size: 10, font_color: "red")
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [[:begin_marked_content, [:Tx]],
                          [:save_graphics_state],
                          [:append_rectangle, [1, 1, 98, 28]],
                          [:clip_path_non_zero],
                          [:end_path],
                          [:save_graphics_state],
                          [:set_leading, [11.5625]],
                          [:set_font_and_size, [:F1, 10]],
                          [:set_device_rgb_non_stroking_color, [1.0, 0.0, 0.0]],
                          [:begin_text],
                          [:move_text, [2, 16.195]],
                          [:show_text, ['Test']],
                          [:move_text_next_line],
                          [:show_text, ['Value']],
                          [:end_text],
                          [:restore_graphics_state],
                          [:restore_graphics_state],
                          [:end_marked_content]])

        @field[:V] = "Test\nTest\nTest"
        @field.set_default_appearance_string(font_size: 0)
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [[:begin_marked_content, [:Tx]],
                          [:save_graphics_state],
                          [:append_rectangle, [1, 1, 98, 28]],
                          [:clip_path_non_zero],
                          [:end_path],
                          [:save_graphics_state],
                          [:set_leading, [9.25]],
                          [:set_font_and_size, [:F1, 8]],
                          [:begin_text],
                          [:move_text, [2, 18.556]],
                          [:show_text, ['Test']],
                          [:move_text_next_line],
                          [:show_text, ['Test']],
                          [:move_text_next_line],
                          [:show_text, ['Test']],
                          [:end_text],
                          [:restore_graphics_state],
                          [:restore_graphics_state],
                          [:end_marked_content]])
      end
    end

    describe "comb text fields" do
      before do
        @field.set_default_appearance_string(font_size: 10)
        @field.initialize_as_comb_text_field
        @field[:MaxLen] = 10
        @widget[:Rect].height = 20
        @widget[:Rect].width = 100
      end

      describe "quadding e.g. text alignment" do
        before do
          @field[:V] = 'Test'
        end

        it "works for left aligned text" do
          @field.text_alignment(:left)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [2.945, 6.41]],
                           range: 7)
        end

        it "works for right aligned text" do
          @field.text_alignment(:right)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [62.945, 6.41]],
                           range: 7)
        end

        it "works for center aligned text" do
          @field.text_alignment(:center)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [32.945, 6.41]],
                           range: 7)
        end

        it "handles centering like Adobe, e.g. shift left, when text cannot be completely centered" do
          @field[:V] = 'Hello'
          @field.text_alignment(:center)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:move_text, [22.39, 6.41]],
                           range: 7)
        end
      end

      it "creates the /N appearance stream according to the set string" do
        @field[:V] = 'Text'
        @field.set_default_appearance_string(font_size: 10, font_color: "red")
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [[:begin_marked_content, [:Tx]],
                          [:save_graphics_state],
                          [:append_rectangle, [1, 1, 98, 18]],
                          [:clip_path_non_zero],
                          [:end_path],
                          [:set_font_and_size, [:F1, 10]],
                          [:set_device_rgb_non_stroking_color, [1.0, 0.0, 0.0]],
                          [:begin_text],
                          [:move_text, [2.945, 6.41]],
                          [:show_text_with_positioning, [['T', -416.5, 'e', -472, 'x', -611, 't']]],
                          [:end_text],
                          [:restore_graphics_state],
                          [:end_marked_content]])
      end

      it "works for empty strings" do
        @field[:V] = ''
        @generator.create_appearances
        assert_operators(@widget[:AP][:N].stream,
                         [[:begin_text],
                          [:move_text, [2, 6.41]],
                          [:end_text]], range: 6..8)
      end

      it "fails if the /MaxLen key is not set" do
        @field.delete(:MaxLen)
        @field[:V] = 't'
        assert_raises(HexaPDF::Error) { @generator.create_appearances }
      end

      it "fails if fallback glyphs are needed for rendering" do
        @doc.config['font.on_invalid_glyph'] = lambda do |codepoint, _|
          [@doc.fonts.add('ZapfDingbats').decode_codepoint(codepoint)]
        end
        @field[:V] = 'Test ✂'
        ex = assert_raises(HexaPDF::Error) { @generator.create_appearances }
        assert_match(/Fallback glyphs/, ex.message)
      end
    end

    describe "choice fields" do
      it "works for combo boxes by using the text appearance method" do
        @form.set_default_appearance_string
        field = @doc.add({FT: :Ch}, type: :XXAcroFormField, subtype: :Ch)
        field.initialize_as_combo_box
        field.flag(:edit)
        field.field_value = 'Test'
        widget = field.create_widget(@page, Rect: [0, 0, 0, 0])
        generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(widget)
        generator.create_appearances
        assert_kind_of(HexaPDF::Type::Form, widget[:AP][:N])
      end

      describe "list boxes" do
        before do
          @field = @doc.add({FT: :Ch}, type: :XXAcroFormField, subtype: :Ch)
          @field.initialize_as_list_box
          @field.flag(:multi_select)
          @field.option_items = ['a', 'b', 'c']
          @widget = @field.create_widget(@page, Rect: [0, 0, 90, 36])
          @generator = HexaPDF::Type::AcroForm::AppearanceGenerator.new(@widget)
        end

        it "uses a fixed font size for list box items if auto-sizing is used" do
          @field.set_default_appearance_string(font_size: 0)
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [:set_font_and_size, [:F1, 12]],
                           range: 8)
        end

        it "uses the set values instead of the ones from /I if in conflict" do
          @field[:I] = [0, 1]
          @field[:V] = ['b']
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [[:set_device_rgb_non_stroking_color, [0.6, 0.756863, 0.854902]],
                            [:append_rectangle, [1, 7.25, 88, 13.875]],
                            [:fill_path_non_zero]],
                           range: 5..7)
        end

        it "creates the /N appearance stream" do
          @field[:I] = [1, 2]
          @field[:V] = ['b', 'c']
          @field.set_default_appearance_string(font_size: 12, font_color: "red")
          @generator.create_appearances
          assert_operators(@widget[:AP][:N].stream,
                           [[:begin_marked_content, [:Tx]],
                            [:save_graphics_state],
                            [:append_rectangle, [1, 1, 88, 34]],
                            [:clip_path_non_zero], [:end_path],
                            [:set_device_rgb_non_stroking_color, [0.6, 0.756863, 0.854902]],
                            [:append_rectangle, [1, 7.25, 88, 13.875]],
                            [:append_rectangle, [1, -6.625, 88, 13.875]],
                            [:fill_path_non_zero],
                            [:save_graphics_state],
                            [:set_leading, [13.875]],
                            [:set_font_and_size, [:F1, 12]],
                            [:set_device_rgb_non_stroking_color, [1.0, 0.0, 0.0]],
                            [:begin_text],
                            [:move_text, [2, 23.609]],
                            [:show_text, ["a"]],
                            [:move_text_next_line],
                            [:show_text, ["b"]],
                            [:end_text],
                            [:restore_graphics_state], [:restore_graphics_state],
                            [:end_marked_content]])
        end
      end
    end

    describe "font resolution in case the referenced font is not usable" do
      before do
        @doc.config['acro_form.fallback_font'] = ['Times', {variant: :italic}]
        @field[:V] = 'Test'
      end

      it "uses the fallback font if the font is not usable" do
        def (@form.default_resources.font(:F1)).font_wrapper; nil; end
        @generator.create_appearances
        assert_equal(:'Times-Italic', @widget[:AP][:N][:Resources][:Font][:F2][:BaseFont])
      end

      it "uses the fallback font if the font is not found" do
        @form.default_resources[:Font].delete(:F1)
        @generator.create_appearances
        assert_equal(:'Times-Italic', @widget[:AP][:N][:Resources][:Font][:F1][:BaseFont])
      end

      it "respects a simple fallback font name" do
        @doc.config['acro_form.fallback_font'] = 'Times'
        @form.default_resources[:Font].delete(:F1)
        @generator.create_appearances
        assert_equal(:'Times-Roman', @widget[:AP][:N][:Resources][:Font][:F1][:BaseFont])
      end

      it "respects a fallback font callable object" do
        field = @field
        @doc.config['acro_form.fallback_font'] = proc do |field_arg, font_arg|
          assert_same(field.data, field_arg.data)
          assert_nil(font_arg)
          'Times'
        end
        @form.default_resources[:Font].delete(:F1)
        @generator.create_appearances
        assert_equal(:'Times-Roman', @widget[:AP][:N][:Resources][:Font][:F1][:BaseFont])
      end

      it "fails if fallback fonts are disabled" do
        @doc.config['acro_form.fallback_font'] = nil
        @form.default_resources[:Font].delete(:F1)
        msg = assert_raises(HexaPDF::Error) { @generator.create_appearances }
        assert_match(/Font.*not usable/, msg.message)
      end
    end
  end
end
