# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/type/acro_form/form'

describe HexaPDF::Type::AcroForm::Form do
  before do
    @doc = HexaPDF::Document.new
    @acro_form = @doc.add({Fields: []}, type: :XXAcroForm)
    @doc.catalog[:AcroForm] = @acro_form
  end

  describe "signature flags" do
    before do
      @acro_form[:SigFlags] = 3
    end

    it "returns all signature flags" do
      assert_equal([:signatures_exist, :append_only], @acro_form.signature_flags)
    end

    it "returns true if the given flag is set" do
      assert(@acro_form.signature_flag?(:signatures_exist))
    end

    it "raises an error if an unknown flag name is provided" do
      assert_raises(ArgumentError) { @acro_form.signature_flag?(:non_exist) }
    end

    it "sets the given flag bits" do
      @acro_form[:SigFlags] = 0
      @acro_form.signature_flag(:append_only)
      assert_equal([:append_only], @acro_form.signature_flags)
      @acro_form.signature_flag(:signatures_exist, clear_existing: true)
      assert_equal([:signatures_exist], @acro_form.signature_flags)
    end
  end

  it "returns the root fields" do
    assert_equal([], @acro_form.root_fields.value)
  end

  it "finds the root fields" do
    @doc.pages.add[:Annots] = [{Subtype: :Widget, Rect: [0, 0, 0, 0], FT: :Tx},
                               {Subtype: :Widget, Rect: [0, 0, 0, 0], FT: :Tx, Parent: {FT: :Tx}}]
    @doc.pages.add[:Annots] = [{Subtype: :Widget, Rect: [0, 0, 0, 0]}]
    @doc.pages.add

    result = [{Subtype: :Widget, Rect: [0, 0, 0, 0], FT: :Tx}, {FT: :Tx}]
    root_fields = @acro_form.find_root_fields
    assert_equal(result, root_fields.map(&:value))
    assert_kind_of(HexaPDF::Type::AcroForm::TextField, root_fields[0])
    assert_equal([], @acro_form[:Fields].value)

    @acro_form.find_root_fields!
    assert_equal(result, @acro_form[:Fields].value.map(&:value))
  end

  describe "each_field" do
    before do
      @acro_form[:Fields] = [
        {T: :Tx1},
        {T: :Tx2, Kids: [{Subtype: :Widget}]},
        {T: :Tx3, FT: :Tx, Kids: [{T: :Tx4}, {T: :Tx5, Kids: [{T: :Tx6}]}]},
      ]
      @acro_form[:Fields][2][:Kids][0][:Parent] = @acro_form[:Fields][2]
      @acro_form[:Fields][2][:Kids][1][:Parent] = @acro_form[:Fields][2]
      @acro_form[:Fields][2][:Kids][1][:Kids][0][:Parent] = @acro_form[:Fields][2][:Kids][1]
    end

    it "iterates over all terminal fields" do
      assert_equal([:Tx1, :Tx2, :Tx4, :Tx6], @acro_form.each_field.map {|h| h[:T] })
    end

    it "iterates over all fields" do
      assert_equal([:Tx1, :Tx2, :Tx3, :Tx4, :Tx5, :Tx6],
                   @acro_form.each_field(terminal_only: false).map {|h| h[:T] })
    end

    it "converts the fields into their proper types if possible" do
      assert_kind_of(HexaPDF::Type::AcroForm::TextField, @acro_form.each_field.to_a.last)
    end

    it "gracefully handles null entries" do
      @acro_form[:Fields].insert(1, HexaPDF::Reference.new(100, 0))
      @acro_form[:Fields][-1][:Kids].insert(1, nil)
      assert_equal([:Tx1, :Tx2, :Tx4, :Tx6], @acro_form.each_field.map {|h| h[:T] })
    end
  end

  describe "field_by_name" do
    before do
      @acro_form[:Fields] = [
        {T: "root only", Kids: [{Subtype: :Widget}]},
        {T: "children", Kids: [{T: "\xFE\xFF".b << "child".encode('UTF-16BE').b, FT: :Btn},
                               {T: "sub", Kids: [{T: "child"}]}]},
      ]
    end

    it "works for root fields" do
      assert(@acro_form.field_by_name("root only"))
    end

    it "works for 1st level children" do
      assert(@acro_form.field_by_name("children.child"))
    end

    it "works for children on any level" do
      assert(@acro_form.field_by_name("children.sub.child"))
    end

    it "returns nil for unknown fields" do
      assert_nil(@acro_form.field_by_name("non root field"))
      assert_nil(@acro_form.field_by_name("root only.no child"))
      assert_nil(@acro_form.field_by_name("root only.no"))
      assert_nil(@acro_form.field_by_name("children.no child"))
      assert_nil(@acro_form.field_by_name("children.sub.no child"))
    end

    it "returns the correct field class" do
      assert_kind_of(HexaPDF::Type::AcroForm::ButtonField, @acro_form.field_by_name('children.child'))
    end
  end

  describe "create fields" do
    before do
      @acro_form = @doc.acro_form(create: true)
    end

    it "creates a pure namespace field" do
      field = @acro_form.create_namespace_field('text')
      assert_equal('text', field.full_field_name)
      assert_nil(field.concrete_field_type)
    end

    describe "handles the general case" do
      it "works for names with a dot" do
        @acro_form[:Fields] = [{T: "root"}]
        field = @acro_form.create_text_field("root.field")
        assert_equal('root.field', field.full_field_name)
        assert_equal([field], @acro_form[:Fields][0][:Kids])
      end

      it "works for names without a dot" do
        field = @acro_form.create_text_field("field")
        assert_equal('field', field.full_field_name)
        assert([field], @acro_form[:Fields])
      end

      it "creates the parent fields as namespace fields if necessary" do
        field = @acro_form.create_text_field("root.sub.field")
        level1 = @acro_form.field_by_name('root')
        assert_equal(1, level1[:Kids].size)
        level2 = @acro_form.field_by_name('root.sub')
        assert_equal(1, level2[:Kids].size)
        assert_same(field, level2[:Kids][0])
      end
    end

    def applies_variable_text_properties(method, **args)
      field = @acro_form.send(method, "field", **args)
      font_name, font_size, font_color = field.parse_default_appearance_string
      assert_equal(:'Helvetica', @acro_form.default_resources.font(font_name)[:BaseFont])
      assert_equal(0, font_size)
      assert_equal(HexaPDF::Content::ColorSpace::DeviceGray.new.color(0), font_color)
      assert_equal(0, field.value[:Q])

      field = @acro_form.send(method, "field", **args, font: 'Times')
      font_name, font_size, font_color = field.parse_default_appearance_string
      assert_equal(:'Times-Roman', @acro_form.default_resources.font(font_name)[:BaseFont])

      field = @acro_form.send(method, "field", **args, font_options: {variant: :bold})
      font_name, = field.parse_default_appearance_string
      assert_equal(:'Helvetica-Bold', @acro_form.default_resources.font(font_name)[:BaseFont])

      field = @acro_form.send(method, "field", **args, font_size: 10)
      font_name, font_size = field.parse_default_appearance_string
      assert_equal(10, font_size)

      field = @acro_form.send(method, "field", **args, font_color: "red")
      _, _, font_color = field.parse_default_appearance_string
      assert_equal(HexaPDF::Content::ColorSpace::DeviceRGB.new.color(255, 0, 0), font_color)

      field = @acro_form.send(method, "field", **args, font: 'Courier', font_size: 10, align: :center)
      font_name, font_size = field.parse_default_appearance_string
      assert_equal(:Courier, @acro_form.default_resources.font(font_name)[:BaseFont])
      assert_equal(10, font_size)
      assert_equal(:center, field.text_alignment)
    end

    it "creates a text field" do
      field = @acro_form.create_text_field("field")
      assert_equal(:Tx, field.field_type)
      applies_variable_text_properties(:create_text_field)
    end

    it "creates a multiline text field" do
      field = @acro_form.create_multiline_text_field("field")
      assert_equal(:Tx, field.field_type)
      assert(field.multiline_text_field?)
      applies_variable_text_properties(:create_multiline_text_field)
    end

    it "creates a comb text field" do
      field = @acro_form.create_comb_text_field("field", max_chars: 9)
      assert_equal(:Tx, field.field_type)
      assert_equal(9, field[:MaxLen])
      assert(field.comb_text_field?)
      applies_variable_text_properties(:create_comb_text_field, max_chars: 9)
    end

    it "creates a password field" do
      field = @acro_form.create_password_field("field")
      assert_equal(:Tx, field.field_type)
      assert(field.password_field?)
      applies_variable_text_properties(:create_password_field)
    end

    it "creates a file select field" do
      field = @acro_form.create_file_select_field("field")
      assert_equal(:Tx, field.field_type)
      assert(field.file_select_field?)
      applies_variable_text_properties(:create_file_select_field)
    end

    it "creates a check box" do
      field = @acro_form.create_check_box("field")
      assert(field.check_box?)
    end

    it "creates a radio button" do
      field = @acro_form.create_radio_button("field")
      assert(field.radio_button?)
    end

    it "creates a combo box" do
      field = @acro_form.create_combo_box("field", option_items: ['a', 'b', 'c'], editable: true)
      assert(field.combo_box?)
      assert_equal(['a', 'b', 'c'], field.option_items)
      assert(field.flagged?(:edit))
      applies_variable_text_properties(:create_combo_box)
    end

    it "creates a list box" do
      field = @acro_form.create_list_box("field", option_items: ['a', 'b', 'c'], multi_select: true)
      assert(field.list_box?)
      assert_equal(['a', 'b', 'c'], field.option_items)
      assert(field.flagged?(:multi_select))
      applies_variable_text_properties(:create_list_box)
    end

    it "creates a signature field" do
      field = @acro_form.create_signature_field("field")
      assert_equal(:signature_field, field.concrete_field_type)
    end
  end

  describe "delete_field" do
    before do
      @field = @acro_form.create_signature_field("sig")
    end

    it "deletes a field via name" do
      @acro_form.delete_field('sig')
      assert_equal(0, @acro_form.root_fields.size)
    end

    it "deletes a field via field object" do
      @acro_form.delete_field(@field)
      assert_equal(0, @acro_form.root_fields.size)
    end

    it "deletes the set signature object" do
      obj = @doc.add({})
      @field.field_value = obj
      @acro_form.delete_field(@field)
      assert(obj.null?)
    end

    it "deletes a field with an embedded widget annotation" do
      widget = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
      assert_equal(widget, @field)
      refute(@doc.pages[0][:Annots].empty?)
      @acro_form.delete_field(@field)
      assert(@doc.pages[0][:Annots].empty?)
      assert(@field.null?)
    end

    it "deletes all widget annotations from the document and the annotation array" do
      widget1 = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
      widget2 = @field.create_widget(@doc.pages.add, Rect: [0, 0, 0, 0])
      refute(@doc.pages[1][:Annots].empty?)
      @acro_form.delete_field(@field)
      assert(@doc.pages[0][:Annots].empty?)
      assert(@doc.pages[1][:Annots].empty?)
      assert(@doc.object(widget1).null?)
      assert(@doc.object(widget2).null?)
    end

    it "deletes the field from the field hierarchy" do
      @acro_form.delete_field('sig')
      refute(@acro_form.field_by_name('sig'))
      assert(@acro_form[:Fields].empty?)

      @acro_form.create_signature_field("sub.sub.sig")
      @acro_form.delete_field("sub.sub.sig")
      refute(@acro_form.field_by_name('sub.sub.sig'))
      assert(@acro_form[:Fields][0][:Kids][0][:Kids].empty?)
    end

    it "deletes the field itself" do
      @acro_form.delete_field('sig')
      assert(@doc.object(@field).null?)
    end
  end

  describe "fill" do
    it "works for text field types" do
      field = @acro_form.create_text_field('test')
      @acro_form.fill("test" => "value")
      assert_equal("value", field.field_value)
    end

    it "ignores values for password fields" do
      field = @acro_form.create_password_field('test')
      @acro_form.fill("test" => "value")
      assert_nil(field.field_value)
    end

    it "works for radio buttons" do
      field = @acro_form.create_radio_button("test")
      field.create_widget(@doc.pages.add, value: :name)
      @acro_form.fill("test" => "name")
      assert_equal(:name, field.field_value)
    end

    it "works for check boxes" do
      field = @acro_form.create_check_box('test')
      field.create_widget(@doc.pages.add)

      ["t", "true", "y", "yes"].each do |value|
        @acro_form.fill("test" => value)
        assert_equal(:Yes, field.field_value)
        field.field_value = :Off
      end

      ["f", "false", "n", "no"].each do |value|
        @acro_form.fill("test" => value)
        assert_nil(field.field_value)
        field.field_value = :Yes
      end

      field.create_widget(@doc.pages.add, value: :Other)
      @acro_form.fill("test" => "Other")
      assert_equal(:Other, field.field_value)
    end

    it "raises an error if a field is not found" do
      error = assert_raises(HexaPDF::Error) { @acro_form.fill("unknown" => "test") }
      assert_match(/named 'unknown' not found/, error.message)
    end

    it "raises an error if a field type is not supported for filling in" do
      @acro_form.create_check_box('test').initialize_as_push_button
      error = assert_raises(HexaPDF::Error) { @acro_form.fill("test" => "test") }
      assert_match(/push_button not yet supported/, error.message)
    end
  end

  it "returns the default resources" do
    assert_kind_of(HexaPDF::Type::Resources, @acro_form.default_resources)
  end

  describe "set_default_appearance_string" do
    it "uses sane default values if no arguments are provided" do
      @acro_form.set_default_appearance_string
      assert_equal("0.0 g /F1 0 Tf", @acro_form[:DA])
      font = @acro_form.default_resources.font(:F1)
      assert(font)
      assert_equal(:Helvetica, font[:BaseFont])
    end

    it "allows specifying the used font, font size and font color" do
      @acro_form.set_default_appearance_string(font: 'Times', font_options: {variant: :bold},
                                               font_size: 10, font_color: "red")
      assert_equal("1.0 0.0 0.0 rg /F1 10 Tf", @acro_form[:DA])
      assert_equal(:'Times-Bold', @acro_form.default_resources.font(:F1)[:BaseFont])
    end
  end

  it "sets the /NeedAppearances key" do
    @acro_form.need_appearances!
    assert(@acro_form[:NeedAppearances])
  end

  describe "create_appearances" do
    before do
      @tf = @acro_form.create_text_field('test')
      @tf.set_default_appearance_string
      @tf.create_widget(@doc.pages.add)
      @cb = @acro_form.create_check_box('test2')
      @cb.create_widget(@doc.pages.add)
    end

    it "creates the appearances of all field widgets if necessary" do
      @acro_form.create_appearances
      assert(@tf.each_widget.all? {|w| w.appearance_dict.normal_appearance.kind_of?(HexaPDF::Stream) })
      assert(@cb.each_widget.all? {|w| w.appearance_dict.normal_appearance[:Yes].kind_of?(HexaPDF::Stream) })
    end

    it "force the creation of appearances if force is true" do
      @acro_form.create_appearances
      text_stream = @tf[:AP][:N].raw_stream
      @acro_form.create_appearances
      assert_same(text_stream, @tf[:AP][:N].raw_stream)
      @acro_form.create_appearances(force: true)
      refute_same(text_stream, @tf[:AP][:N].raw_stream)
    end
  end

  describe "flatten" do
    before do
      @acro_form.root_fields << @doc.wrap({T: 'test'})
      @tf = @acro_form.create_text_field('textfields')
      @tf.set_default_appearance_string
      @tf[:V] = 'Test'
      @tf.create_widget(@doc.pages.add)
      @cb = @acro_form.create_check_box('test.checkbox')
      @cb.create_widget(@doc.pages[0])
      @cb.create_widget(@doc.pages.add)
    end

    it "creates the missing appearances if instructed to do so" do
      assert_equal(3, @acro_form.flatten(create_appearances: false).size)
      assert_equal(0, @acro_form.flatten(create_appearances: true).size)
    end

    it "flattens the whole interactive form" do
      result = @acro_form.flatten
      assert(result.empty?)
      assert(@tf.null?)
      assert(@cb.null?)
      assert(@acro_form.null?)
      refute(@doc.catalog.key?(:AcroForm))
    end

    it "flattens the given fields" do
      result = @acro_form.flatten(fields: [@cb])
      assert(result.empty?)
      assert(@cb.null?)
      refute(@tf.null?)
      refute(@acro_form.null?)
      assert(@doc.catalog.key?(:AcroForm))
    end

    it "doesn't delete the form object if not all fields were flattened" do
      @acro_form.create_appearances
      @tf.delete(:AP)
      result = @acro_form.flatten(create_appearances: false)
      assert_equal(1, result.size)
      assert(@doc.catalog.key?(:AcroForm))
    end

    it "returns the fields that could not be flattened" do
      @cb.create_appearances
      result = @acro_form.flatten(create_appearances: false)
      assert_equal([@tf], result)
    end
  end

  describe "recalculate_fields" do
    before do
      @text1 = @acro_form.create_text_field('text1')
      @text2 = @acro_form.create_text_field('text2')
      @text3 = @acro_form.create_text_field('text3')
    end

    it "recalculates all fields listed in /CO" do
      @text1.field_value = "10"
      @text2.field_value = "30"
      @text3.set_calculate_action(:sum, fields: ['text1', @text2])
      @acro_form.recalculate_fields
      assert_equal("40", @text3.field_value)
    end

    it "doesn't change the field's value if there is an error" do
      @text3.set_calculate_action(:sfn, fields: 'text1 - text2')
      @text3[:AA][:C][:JS] = @text3[:AA][:C][:JS].sub('text1', 'text4')
      @acro_form.recalculate_fields
      assert_nil(@text3.field_value)
    end

    it "works if fields aren't already loaded and correctly wrapped" do
      @text1.field_value = "10"
      @text3.set_calculate_action(:sfn, fields: 'text1')
      @text3[:AA] = {C: HexaPDF::Reference.new(@doc.add(@text3[:AA][:C]).oid)}
      @acro_form[:CO] = [HexaPDF::Reference.new(@text3.oid, @text3.gen)]
      @doc.revisions.current.update(@doc.wrap(@text3, type: HexaPDF::Dictionary))
      @acro_form.recalculate_fields
      assert_equal("10", @text3.field_value)
    end

    it "ensures that only entries in /CO that are actually fields are used" do
      @text1.field_value = "10"
      @text3.set_calculate_action(:sfn, fields: 'text1')
      @acro_form[:CO] = [nil, 5, [:some, :array], @doc.pages.root, @text3]
      @acro_form.recalculate_fields
      assert_equal("10", @text3.field_value)
    end
  end

  describe "perform_validation" do
    it "checks whether the /DR field is available when /DA is set" do
      @acro_form[:DA] = 'test'
      refute(@acro_form.validate)
    end

    it "checks whether the font used in /DA is available in /DR" do
      @acro_form[:DA] = '/F2 0 Tf /F1 0 Tf'
      refute(@acro_form.validate {|msg| assert_match(/DR must also be present/, msg) })
      @acro_form.default_resources[:Font] = {}
      refute(@acro_form.validate {|msg| assert_match(/font.*is not.*resource/, msg) })
      @acro_form.default_resources[:Font][:F1] = :yes
      assert(@acro_form.validate)
    end

    describe "field hierarchy validation" do
      before do
        @acro_form[:Fields] = [
          nil,
          HexaPDF::Object.new(nil),
          5,
          HexaPDF::Object.new(5),
          @doc.add({T: :Tx1}),
          @doc.add({T: :Tx2, Kids: [nil, @doc.add({Subtype: :Widget})]}),
          @doc.add({T: :Tx3, FT: :Tx, Kids: [@doc.add({T: :Tx4}),
                                             [:nothing],
                                             @doc.add({T: :Tx5, Kids: [@doc.add({T: :Tx6})]})]}),
        ]
        @acro_form[:Fields][6][:Kids][0][:Parent] = @acro_form[:Fields][6]
        @acro_form[:Fields][6][:Kids][2][:Parent] = @acro_form[:Fields][6]
        @acro_form[:Fields][6][:Kids][2][:Kids][0][:Parent] = @acro_form[:Fields][6][:Kids][2]
      end

      it "removes invalid objects from the field hierarchy" do
        assert(@acro_form.validate)
        assert_equal([:Tx1, :Tx2, :Tx3, :Tx4, :Tx5, :Tx6],
                     @acro_form.each_field(terminal_only: false).map {|f| f[:T] })
      end

      it "handles missing /Parent fields" do
        @acro_form[:Fields][6][:Kids][0].delete(:Parent)
        assert(@acro_form.validate)
        assert_equal(1, @acro_form[:Fields][2][:Kids].size)
        assert_equal(:Tx5, @acro_form[:Fields][2][:Kids][0][:T])
        assert_equal(:Tx4, @acro_form[:Fields][3][:T])
      end

      it "handles /Parent field pointing to somewhere else" do
        @acro_form[:Fields][6][:Kids][0][:Parent] = @acro_form[:Fields][4]
        assert(@acro_form.validate)
        assert_equal(2, @acro_form[:Fields][2][:Kids].size)
        assert_equal(:Tx4, @acro_form[:Fields][2][:Kids][0][:T])
        assert_equal(@acro_form[:Fields][2], @acro_form[:Fields][2][:Kids][0][:Parent])
      end

      it "ensures that objects loaded as widget are stored as field" do
        @acro_form[:Fields][2] = @doc.add({T: :WidgetField, Type: :Annot, Subtype: :Widget})
        assert_kind_of(HexaPDF::Type::Annotations::Widget, @acro_form[:Fields][2])

        assert(@acro_form.validate)
        field = @acro_form[:Fields][0]
        assert_kind_of(HexaPDF::Type::AcroForm::Field, field)
        assert_equal(:WidgetField, field.full_field_name)
      end
    end

    describe "combining fields with the same name" do
      before do
        @acro_form[:Fields] = [
          @doc.add({T: 'e', Subtype: :Widget, Rect: [0, 0, 0, 1]}),
          @merged_field = @doc.add({T: 'e', Subtype: :Widget, Rect: [0, 0, 0, 2]}),
          @doc.add({T: 'Tx2'}),
          @doc.add({T: 'e', Kids: [{Subtype: :Widget, Rect: [0, 0, 0, 3]}]}),
        ]
      end

      it "merges fields with the same name into the first one" do
        assert(@acro_form.validate)
        assert_equal(2, @acro_form.root_fields.size)
        assert_equal([[0, 0, 0, 1], [0, 0, 0, 2], [0, 0, 0, 3]],
                     @acro_form.field_by_name('e').each_widget.map {|w| w[:Rect] })
      end

      it "deletes the combined and now unneeded field objects" do
        assert(@acro_form.validate)
        assert(@merged_field.null?)
        assert(@doc.object(@merged_field.oid).null?)
      end
    end

    describe "automatically creates the terminal fields; appearances" do
      before do
        @cb = @acro_form.create_check_box('test2')
        @cb.create_widget(@doc.pages.add)
      end

      it "does this if the configuration option is true" do
        assert(@acro_form.validate)
        assert_kind_of(HexaPDF::Stream, @cb[:AP][:N][:Yes])
      end

      it "does nothing if the configuration option is false" do
        @doc.config['acro_form.create_appearances'] = false
        assert(@acro_form.validate)
        refute_kind_of(HexaPDF::Stream, @cb[:AP][:N][:Yes])
      end
    end
  end
end
