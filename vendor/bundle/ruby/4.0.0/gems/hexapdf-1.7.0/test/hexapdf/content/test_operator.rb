# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/operator'
require 'hexapdf/content/processor'
require 'hexapdf/serializer'

describe HexaPDF::Content::Operator::BaseOperator do
  before do
    @op = HexaPDF::Content::Operator::BaseOperator.new('name')
  end

  it "takes a name on initialization and can return it" do
    assert_equal('name', @op.name)
    assert(@op.name.frozen?)
  end

  it "responds to invoke" do
    assert_respond_to(@op, :invoke)
  end

  it "can serialize any operator with its operands" do
    serializer = HexaPDF::Serializer.new
    assert_equal("5.0 5 /Name name\n", @op.serialize(serializer, 5.0, 5, :Name))
  end
end

describe HexaPDF::Content::Operator::NoArgumentOperator do
  it "provides a special serialize method" do
    op = HexaPDF::Content::Operator::NoArgumentOperator.new('name')
    assert_equal("name\n", op.serialize(nil))
  end
end

describe HexaPDF::Content::Operator::SingleNumericArgumentOperator do
  it "provides a special serialize method" do
    op = HexaPDF::Content::Operator::SingleNumericArgumentOperator.new('name')
    serializer = HexaPDF::Serializer.new
    assert_equal("5 name\n", op.serialize(serializer, 5))
    assert_equal("5.45 name\n", op.serialize(serializer, 5.45))
  end
end

module CommonOperatorTests
  extend Minitest::Spec::DSL

  before do
    resources = {}
    resources.define_singleton_method(:color_space) do |name|
      HexaPDF::GlobalConfiguration.constantize('color_space.map', name).new
    end
    resources.define_singleton_method(:ext_gstate) do |name|
      self[:ExtGState] && self[:ExtGState][name] || raise(HexaPDF::Error, "missing")
    end
    @processor = HexaPDF::Content::Processor.new(resources)
    @serializer = HexaPDF::Serializer.new
  end

  # calls the method of the operator with the operands
  def call(method, *operands)
    HexaPDF::Content::Operator::DEFAULT_OPERATORS[@name].send(method, *operands)
  end

  # calls the invoke method on the operator
  def invoke(*operands)
    call(:invoke, @processor, *operands)
  end

  it "is associated with the correct operator name in the default mapping" do
    assert_equal(@name, call(:name).to_sym)
  end

  it "is not the base operator implementation" do
    refute_equal(HexaPDF::Content::Operator::BaseOperator, call(:class))
  end

  def assert_serialized(*operands)
    op = HexaPDF::Content::Operator::BaseOperator.new(@name.to_s)
    assert_equal(op.serialize(@serializer, *operands), call(:serialize, @serializer, *operands))
  end

end

def describe_operator(name, symbol, &block)
  klass_name = "HexaPDF::Content::Operator::#{name}"
  klass = describe(klass_name, &block)
  klass.send(:include, CommonOperatorTests)
  one_time_module = Module.new
  one_time_module.send(:define_method, :setup) do
    super()
    @name = symbol
  end
  one_time_module.send(:define_method, :test_class_name) do
    assert_equal(klass_name, call(:class).name)
  end
  klass.send(:include, one_time_module)
  klass
end

describe_operator :SaveGraphicsState, :q do
  it "saves the graphics state" do
    width = @processor.graphics_state.line_width
    invoke
    @processor.graphics_state.line_width = 10
    @processor.graphics_state.restore
    assert_equal(width, @processor.graphics_state.line_width)
  end
end

describe_operator :RestoreGraphicsState, :Q do
  it "restores the graphics state" do
    width = @processor.graphics_state.line_width
    @processor.graphics_state.save
    @processor.graphics_state.line_width = 10
    invoke
    assert_equal(width, @processor.graphics_state.line_width)
  end
end

describe_operator :ConcatenateMatrix, :cm do
  it "concatenates the ctm by pre-multiplication" do
    invoke(1, 2, 3, 4, 5, 6)
    invoke(6, 5, 4, 3, 2, 1)
    assert_equal(21, @processor.graphics_state.ctm.a)
    assert_equal(32, @processor.graphics_state.ctm.b)
    assert_equal(13, @processor.graphics_state.ctm.c)
    assert_equal(20, @processor.graphics_state.ctm.d)
    assert_equal(10, @processor.graphics_state.ctm.e)
    assert_equal(14, @processor.graphics_state.ctm.f)
  end

  it "serializes correctly" do
    assert_serialized(1, 2, 3, 4, 5, 6)
  end
end

describe_operator :SetLineWidth, :w do
  it "sets the line width" do
    invoke(10)
    assert_equal(10, @processor.graphics_state.line_width)
  end
end

describe_operator :SetLineCapStyle, :J do
  it "sets the line cap" do
    invoke(HexaPDF::Content::LineCapStyle::ROUND_CAP)
    assert_equal(HexaPDF::Content::LineCapStyle::ROUND_CAP,
                 @processor.graphics_state.line_cap_style)
  end
end

describe_operator :SetLineJoinStyle, :j do
  it "sets the line join" do
    invoke(HexaPDF::Content::LineJoinStyle::ROUND_JOIN)
    assert_equal(HexaPDF::Content::LineJoinStyle::ROUND_JOIN,
                 @processor.graphics_state.line_join_style)
  end
end

describe_operator :SetMiterLimit, :M do
  it "sets the miter limit" do
    invoke(100)
    assert_equal(100, @processor.graphics_state.miter_limit)
  end
end

describe_operator :SetLineDashPattern, :d do
  it "sets the line dash pattern" do
    invoke([3, 4], 5)
    assert_equal(HexaPDF::Content::LineDashPattern.new([3, 4], 5),
                 @processor.graphics_state.line_dash_pattern)
  end

  it "serializes correctly" do
    assert_serialized([3, 4], 5)
  end
end

describe_operator :SetRenderingIntent, :ri do
  it "sets the rendering intent" do
    invoke(HexaPDF::Content::RenderingIntent::SATURATION)
    assert_equal(HexaPDF::Content::RenderingIntent::SATURATION,
                 @processor.graphics_state.rendering_intent)
  end

  it "serializes correctly" do
    assert_serialized(HexaPDF::Content::RenderingIntent::SATURATION)
  end
end

describe_operator :SetGraphicsStateParameters, :gs do
  it "applies parameters from an ExtGState dictionary" do
    font = Object.new
    font.define_singleton_method(:glyph_scaling_factor) { 0.01 }
    @processor.resources[:ExtGState] = {Name: {LW: 10, LC: 2, LJ: 2, ML: 2, D: [[3, 5], 2],
                                               RI: 2, SA: true, BM: :Multiply, CA: 0.5, ca: 0.5,
                                               AIS: true, TK: false, Font: [font, 10],
                                               SMask: {Type: :Mask, S: :Luminosity}}}
    @processor.resources.define_singleton_method(:document) do
      Object.new.tap {|obj| obj.define_singleton_method(:deref) {|o| o } }
    end

    invoke(:Name)
    gs = @processor.graphics_state
    assert_equal(10, gs.line_width)
    assert_equal(2, gs.line_cap_style)
    assert_equal(2, gs.line_join_style)
    assert_equal(2, gs.miter_limit)
    assert_equal(HexaPDF::Content::LineDashPattern.new([3, 5], 2), gs.line_dash_pattern)
    assert_equal(2, gs.rendering_intent)
    assert(gs.stroke_adjustment)
    assert_equal(:Multiply, gs.blend_mode)
    assert_equal(0.5, gs.stroke_alpha)
    assert_equal(0.5, gs.fill_alpha)
    assert(gs.alpha_source)
    assert_equal({Type: :Mask, S: :Luminosity}, gs.soft_mask)
    assert_equal(font, gs.font)
    assert_equal(10, gs.font_size)
    refute(gs.text_knockout)
  end

  it "fails if the resources dictionary doesn't have an ExtGState entry" do
    assert_raises(HexaPDF::Error) { invoke(:Name) }
  end

  it "fails if the ExtGState resources doesn't have the specified dictionary" do
    @processor.resources[:ExtGState] = {}
    assert_raises(HexaPDF::Error) { invoke(:Name) }
  end

  it "serializes correctly" do
    assert_serialized(:Name)
  end
end

describe_operator :SetStrokingColorSpace, :CS do
  it "sets the stroking color space" do
    invoke(:DeviceRGB)
    assert_equal(@processor.resources.color_space(:DeviceRGB), @processor.graphics_state.stroke_color_space)
  end

  it "serializes correctly" do
    assert_serialized(:DeviceRGB)
  end
end

describe_operator :SetNonStrokingColorSpace, :cs do
  it "sets the non stroking color space" do
    invoke(:DeviceRGB)
    assert_equal(@processor.resources.color_space(:DeviceRGB),
                 @processor.graphics_state.fill_color_space)
  end

  it "serializes correctly" do
    assert_serialized(:DeviceRGB)
  end
end

describe_operator :SetStrokingColor, :SC do
  it "sets the stroking color" do
    invoke(0.2)
    assert_equal(@processor.resources.color_space(:DeviceGray).color(51),
                 @processor.graphics_state.stroke_color)
  end

  it "serializes correctly" do
    assert_serialized(0.2, 0.5, 0.8)
  end
end

describe_operator :SetNonStrokingColor, :sc do
  it "sets the non stroking color" do
    invoke(0.2)
    assert_equal(@processor.resources.color_space(:DeviceGray).color(51),
                 @processor.graphics_state.fill_color)
  end

  it "serializes correctly" do
    assert_serialized(0.2, 0.5, 0.8)
  end
end

describe_operator :SetDeviceGrayStrokingColor, :G do
  it "sets the DeviceGray stroking color" do
    invoke(0.2)
    assert_equal(@processor.resources.color_space(:DeviceGray).color(51),
                 @processor.graphics_state.stroke_color)
  end
end

describe_operator :SetDeviceGrayNonStrokingColor, :g do
  it "sets the DeviceGray non stroking color" do
    invoke(0.2)
    assert_equal(@processor.resources.color_space(:DeviceGray).color(51),
                 @processor.graphics_state.fill_color)
  end
end

describe_operator :SetDeviceRGBStrokingColor, :RG do
  it "sets the DeviceRGB stroking color" do
    invoke(0.2, 0, 0.2)
    assert_equal(@processor.resources.color_space(:DeviceRGB).color(51, 0, 51),
                 @processor.graphics_state.stroke_color)
  end

  it "serializes correctly" do
    assert_serialized(0.2, 0.3, 0.4)
  end
end

describe_operator :SetDeviceRGBNonStrokingColor, :rg do
  it "sets the DeviceRGB non stroking color" do
    invoke(0.2, 0, 0.2)
    assert_equal(@processor.resources.color_space(:DeviceRGB).color(51, 0, 51),
                 @processor.graphics_state.fill_color)
  end

  it "serializes correctly" do
    assert_serialized(0.2, 0.3, 0.4)
  end
end

describe_operator :SetDeviceCMYKStrokingColor, :K do
  it "sets the DeviceCMYK stroking color" do
    invoke(0.51, 0, 0.51, 0.51)
    assert_equal(@processor.resources.color_space(:DeviceCMYK).color(51, 0, 51, 51),
                 @processor.graphics_state.stroke_color)
  end

  it "serializes correctly" do
    assert_serialized(0.2, 0.3, 0.4, 0.5)
  end
end

describe_operator :SetDeviceCMYKNonStrokingColor, :k do
  it "sets the DeviceCMYK non stroking color" do
    invoke(0.51, 0, 0.51, 0.51)
    assert_equal(@processor.resources.color_space(:DeviceCMYK).color(51, 0, 51, 51),
                 @processor.graphics_state.fill_color)
  end

  it "serializes correctly" do
    assert_serialized(0.2, 0.3, 0.4, 0.5)
  end
end

describe_operator :MoveTo, :m do
  it "changes the graphics object to path" do
    refute_equal(:path, @processor.graphics_object)
    invoke(128, 0)
    assert_equal(:path, @processor.graphics_object)
  end

  it "serializes correctly" do
    assert_serialized(1.54, 1.78)
  end
end

describe_operator :AppendRectangle, :re do
  it "changes the graphics object to path" do
    refute_equal(:path, @processor.graphics_object)
    invoke(128, 0, 10, 10)
    assert_equal(:path, @processor.graphics_object)
  end

  it "serializes correctly" do
    assert_serialized(10, 11, 1.54, 1.78)
  end
end

describe_operator :LineTo, :l do
  it "serializes correctly" do
    assert_serialized(1.54, 1.78)
  end
end

describe_operator :CurveTo, :c do
  it "serializes correctly" do
    assert_serialized(1.54, 1.78, 2, 3, 5, 6)
  end
end

describe_operator :CurveToNoFirstControlPoint, :v do
  it "serializes correctly" do
    assert_serialized(2, 3, 5, 6)
  end
end

describe_operator :CurveToNoSecondControlPoint, :y do
  it "serializes correctly" do
    assert_serialized(2, 3, 5, 6)
  end
end

[:S, :s, :f, :F, :'f*', :B, :'B*', :b, :'b*', :n].each do |sym|
  describe_operator :EndPath, sym do
    it "changes the graphics object to none" do
      @processor.graphics_object = :path
      invoke
      refute_equal(:path, @processor.graphics_object)
    end
  end
end

[:W, :'W*'].each do |sym|
  describe_operator :ClipPath, sym do
    it "changes the graphics object to clipping_path for clip path operations" do
      invoke
      assert_equal(:clipping_path, @processor.graphics_object)
    end
  end
end

describe_operator :InlineImage, :BI do
  it "serializes correctly" do
    assert_equal("BI\n/Name 5 /OP 6 ID\nsome dataEI\n",
                 call(:serialize, @serializer, {Name: 5, OP: 6}, 'some data'))
  end
end

describe_operator :SetCharacterSpacing, :Tc do
  it "modifies the character spacing" do
    invoke(127)
    assert_equal(127, @processor.graphics_state.character_spacing)
  end
end

describe_operator :SetWordSpacing, :Tw do
  it "modifies the word spacing" do
    invoke(127)
    assert_equal(127, @processor.graphics_state.word_spacing)
  end
end

describe_operator :SetHorizontalScaling, :Tz do
  it "modifies the horizontal scaling parameter" do
    invoke(127)
    assert_equal(127, @processor.graphics_state.horizontal_scaling)
  end
end

describe_operator :SetLeading, :TL do
  it "modifies the leading parameter" do
    invoke(127)
    assert_equal(127, @processor.graphics_state.leading)
  end
end

describe_operator :SetFontAndSize, :Tf do
  it "sets the font and size correctly" do
    @processor.resources.define_singleton_method(:font) do |name|
      self[:Font] && self[:Font][name]
    end

    font = Object.new
    font.define_singleton_method(:glyph_scaling_factor) { 0.01 }
    @processor.resources[:Font] = {F1: font}
    invoke(:F1, 10)
    assert_equal(@processor.resources.font(:F1), @processor.graphics_state.font)
    assert_equal(10, @processor.graphics_state.font_size)
  end

  it "serializes correctly" do
    assert_serialized(:Font, 1.78)
  end
end

describe_operator :SetTextRenderingMode, :Tr do
  it "modifies the text rendering mode" do
    invoke(HexaPDF::Content::TextRenderingMode::FILL_STROKE)
    assert_equal(HexaPDF::Content::TextRenderingMode::FILL_STROKE,
                 @processor.graphics_state.text_rendering_mode)
  end
end

describe_operator :SetTextRise, :Ts do
  it "modifies the text rise" do
    invoke(127)
    assert_equal(127, @processor.graphics_state.text_rise)
  end
end

describe_operator :BeginText, :BT do
  it "changes the graphics object to text and the tm/tlm to the identity matrix" do
    @processor.graphics_object = :none
    invoke
    assert_equal(:text, @processor.graphics_object)
    assert_equal(HexaPDF::Content::TransformationMatrix.new, @processor.graphics_state.tm)
    assert_equal(HexaPDF::Content::TransformationMatrix.new, @processor.graphics_state.tlm)
  end
end

describe_operator :EndText, :ET do
  it "changes the graphics object to :none and undefines the text and text line matrices" do
    @processor.graphics_object = :text
    invoke
    assert_equal(:none, @processor.graphics_object)
    assert_nil(@processor.graphics_state.tm)
    assert_nil(@processor.graphics_state.tlm)
  end
end

describe_operator :MoveText, :Td do
  it "correctly updates the text and text line matrices" do
    @processor.graphics_state.tm = HexaPDF::Content::TransformationMatrix.new
    @processor.graphics_state.tlm = HexaPDF::Content::TransformationMatrix.new
    invoke(5, 10)
    assert_equal(HexaPDF::Content::TransformationMatrix.new(1, 0, 0, 1, 5, 10),
                 @processor.graphics_state.tm)
    assert_equal(HexaPDF::Content::TransformationMatrix.new(1, 0, 0, 1, 5, 10),
                 @processor.graphics_state.tlm)
  end

  it "serializes correctly" do
    assert_serialized(1.54, 1.78)
  end
end

describe_operator :MoveTextAndSetLeading, :TD do
  it "invokes the TL and Td operators" do
    tl = Minitest::Mock.new
    tl.expect(:invoke, nil, [@processor, -1.78])
    @processor.operators[:TL] = tl
    td = Minitest::Mock.new
    td.expect(:invoke, nil, [@processor, 1.56, 1.78])
    @processor.operators[:Td] = td

    invoke(1.56, 1.78)
    assert(tl.verify)
    assert(td.verify)
  end

  it "serializes correctly" do
    assert_serialized(1.54, 1.78)
  end
end

describe_operator :SetTextMatrix, :Tm do
  it "correctly sets the text and text line matrices" do
    @processor.graphics_state.tm = HexaPDF::Content::TransformationMatrix.new
    @processor.graphics_state.tlm = HexaPDF::Content::TransformationMatrix.new
    invoke(2, 3, 4, 5, 6, 7)
    assert_equal(HexaPDF::Content::TransformationMatrix.new(2, 3, 4, 5, 6, 7),
                 @processor.graphics_state.tm)
    assert_equal(HexaPDF::Content::TransformationMatrix.new(2, 3, 4, 5, 6, 7),
                 @processor.graphics_state.tlm)
  end

  it "serializes correctly" do
    assert_serialized(1, 2, 3, 4, 5, 6)
  end
end

describe_operator :MoveTextNextLine, :'T*' do
  it "invokes the Td operator" do
    td = Minitest::Mock.new
    td.expect(:invoke, nil, [@processor, 0, -1.78])
    @processor.operators[:Td] = td

    @processor.graphics_state.leading = 1.78
    invoke
    assert(td.verify)
  end
end

describe_operator :ShowText, :Tj do
  it "serializes correctly" do
    assert_equal("(Some Text)Tj\n", call(:serialize, @serializer, "Some Text"))
  end
end

describe_operator :MoveTextNextLineAndShowText, :"'" do
  it "invokes the T* and Tj operators" do
    text = "Some text"

    tstar = Minitest::Mock.new
    tstar.expect(:invoke, nil, [@processor])
    @processor.operators[:'T*'] = tstar
    tj = Minitest::Mock.new
    tj.expect(:invoke, nil, [@processor, text])
    @processor.operators[:Tj] = tj

    invoke(text)
    assert(tstar.verify)
    assert(tj.verify)
  end

  it "serializes correctly" do
    assert_equal("(Some Text)'\n", call(:serialize, @serializer, "Some Text"))
  end
end

describe_operator :SetSpacingMoveTextNextLineAndShowText, :'"' do
  it "invokes the Tw, Tc and ' operators" do
    word_spacing = 10
    char_spacing = 15
    text = "Some text"

    tw = Minitest::Mock.new
    tw.expect(:invoke, nil, [@processor, word_spacing])
    @processor.operators[:Tw] = tw
    tc = Minitest::Mock.new
    tc.expect(:invoke, nil, [@processor, char_spacing])
    @processor.operators[:Tc] = tc
    tapos = Minitest::Mock.new
    tapos.expect(:invoke, nil, [@processor, text])
    @processor.operators[:"'"] = tapos

    invoke(word_spacing, char_spacing, text)
    assert(tw.verify)
    assert(tc.verify)
    assert(tapos.verify)
  end

  it "serializes correctly" do
    assert_equal("10 15 (Some Text)\"\n", call(:serialize, @serializer, 10, 15, "Some Text"))
  end
end

describe_operator :ShowTextWithPositioning, :TJ do
  it "serializes correctly" do
    assert_equal("[(Some Text)15(other text)20(final text)]TJ\n",
                 call(:serialize, @serializer, ["Some Text", 15, "other text", 20, "final text"]))
  end
end
