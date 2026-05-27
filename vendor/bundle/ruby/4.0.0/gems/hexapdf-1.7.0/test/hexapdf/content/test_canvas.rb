# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/content/canvas'
require 'hexapdf/document'
require 'hexapdf/content/processor'
require 'hexapdf/content/parser'

describe HexaPDF::Content::Canvas do
  before do
    @doc = HexaPDF::Document.new
    @doc.config['graphic_object.arc.max_curves'] = 4
    @page = @doc.pages.add
    @canvas = @page.canvas
  end

  # Asserts that a specific operator is invoked when the block is executed.
  def assert_operator_invoked(op, *args)
    mock = Minitest::Mock.new
    if args.empty?
      mock.expect(:invoke, nil) { true }
      mock.expect(:serialize, '') { true }
    else
      mock.expect(:invoke, nil, [@canvas] + args)
      mock.expect(:serialize, '', [@canvas.instance_variable_get(:@serializer)] + args)
    end
    op_before = @canvas.instance_variable_get(:@operators)[op]
    @canvas.instance_variable_get(:@operators)[op] = mock
    yield
    assert(mock.verify)
  ensure
    @canvas.instance_variable_get(:@operators)[op] = op_before
  end

  # Asserts that the block raises an error when in one of the given graphics objects.
  def assert_raises_in_graphics_object(*objects, &block)
    objects.each do |graphics_object|
      @canvas.graphics_object = graphics_object
      assert_raises(HexaPDF::Error, &block)
    end
  end

  describe "contents" do
    it "returns the serialized contents of the canvas operations" do
      @canvas.save_graphics_state {}
      assert_equal("q\nQ\n", @canvas.contents)
    end
  end

  describe "stream_data" do
    it "it closes an open path object" do
      @canvas.move_to(5, 5)
      assert_equal("5 5 m\nn\n", @canvas.stream_data.fiber.resume)
    end

    it "it closes an open text object" do
      @canvas.begin_text
      assert_equal("BT\nET\n", @canvas.stream_data.fiber.resume)
    end

    it "rewinds the graphics state stack" do
      @canvas.save_graphics_state
      @canvas.begin_text
      assert_equal("q\nBT\nET\nQ\n", @canvas.stream_data.fiber.resume)
    end
  end

  describe "resources" do
    it "returns the resources of the context object" do
      assert_equal(@page.resources, @canvas.resources)
    end
  end

  describe "pos" do
    it "returns the transformed position" do
      @canvas.translate(9, 4)
      assert_equal([10, 5], @canvas.pos(1, 1))
    end
  end

  describe "save_graphics_state" do
    it "invokes the operator implementation" do
      assert_operator_invoked(:q) { @canvas.save_graphics_state }
    end

    it "is serialized correctly when no block is used" do
      @canvas.save_graphics_state
      assert_operators(@canvas.contents, [[:save_graphics_state]])
    end

    it "is serialized correctly when a block is used" do
      @canvas.save_graphics_state {}
      assert_operators(@canvas.contents, [[:save_graphics_state], [:restore_graphics_state]])
    end

    it "saves needed font state information not stored in the graphics state" do
      @canvas.save_graphics_state do
        @canvas.font("Times", size: 12)
        @canvas.save_graphics_state do
          @canvas.font("Helvetica")
        end
        assert_equal("Times-Roman", @canvas.font.wrapped_font.font_name)
      end
      assert_nil(@canvas.font)
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) { @canvas.save_graphics_state }
    end
  end

  describe "restore_graphics_state" do
    it "invokes the operator implementation" do
      assert_operator_invoked(:Q) { @canvas.restore_graphics_state }
    end

    it "is serialized correctly" do
      @canvas.graphics_state.save
      @canvas.restore_graphics_state
      assert_operators(@page.contents, [[:restore_graphics_state]])
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) { @canvas.restore_graphics_state }
    end
  end

  describe "transform" do
    it "invokes the operator implementation" do
      assert_operator_invoked(:cm, 1, 2, 3, 4, 5, 6) { @canvas.transform(1, 2, 3, 4, 5, 6) }
    end

    it "is serialized correctly when no block is used" do
      @canvas.transform(1, 2, 3, 4, 5, 6)
      assert_operators(@page.contents, [[:concatenate_matrix, [1, 2, 3, 4, 5, 6]]])
    end

    it "is serialized correctly when a block is used" do
      @canvas.transform(1, 2, 3, 4, 5, 6) {}
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [1, 2, 3, 4, 5, 6]],
                                        [:restore_graphics_state]])
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) { @canvas.transform(1, 2, 3, 4, 5, 6) }
    end
  end

  describe "rotate" do
    it "can rotate around the origin" do
      @canvas.rotate(90)
      assert_operators(@page.contents, [[:concatenate_matrix, [0, 1, -1, 0, 0, 0]]])
    end

    it "can rotate about an arbitrary point" do
      @canvas.rotate(90, origin: [100, 200])
      assert_operators(@page.contents, [[:concatenate_matrix, [0.0, 1.0, -1.0, 0.0, 300.0, 100.0]]])
    end
  end

  describe "scale" do
    it "can scale from the origin" do
      @canvas.scale(5, 10)
      assert_operators(@page.contents, [[:concatenate_matrix, [5, 0, 0, 10, 0, 0]]])
    end

    it "can scale from an arbitrary point" do
      @canvas.scale(5, 10, origin: [100, 200])
      assert_operators(@page.contents, [[:concatenate_matrix, [5, 0, 0, 10, -400, -1800]]])
    end

    it "works with a single scale factor" do
      @canvas.scale(5)
      assert_operators(@page.contents, [[:concatenate_matrix, [5, 0, 0, 5, 0, 0]]])
    end
  end

  describe "translate" do
    it "translates the origin" do
      @canvas.translate(100, 200)
      assert_operators(@page.contents, [[:concatenate_matrix, [1, 0, 0, 1, 100, 200]]])
    end
  end

  describe "skew" do
    it "can skew from the origin" do
      @canvas.skew(45, 0)
      assert_operators(@page.contents, [[:concatenate_matrix, [1, 1, 0, 1, 0, 0]]])
    end

    it "can skew from an arbitrary point" do
      @canvas.skew(45, 0, origin: [100, 200])
      assert_operators(@page.contents, [[:concatenate_matrix, [1, 1, 0, 1, 0, -100]]])
    end
  end

  describe "private gs_getter_setter" do
    it "returns the current value when used with a nil argument" do
      @canvas.graphics_state.line_width = 5
      assert_equal(5, @canvas.send(:gs_getter_setter, :line_width, :w, nil))
    end

    it "returns the canvas object when used with a non-nil argument or a block" do
      assert_equal(@canvas, @canvas.send(:gs_getter_setter, :line_width, :w, 15))
      assert_equal(@canvas, @canvas.send(:gs_getter_setter, :line_width, :w, 15) {})
    end

    it "invokes the operator implementation when a non-nil argument is used" do
      assert_operator_invoked(:w, 5) { @canvas.send(:gs_getter_setter, :line_width, :w, 5) }
      assert_operator_invoked(:w, 15) { @canvas.send(:gs_getter_setter, :line_width, :w, 15) {} }
    end

    it "doesn't add an operator if the value is equal to the current one" do
      @canvas.send(:gs_getter_setter, :line_width, :w,
                   @canvas.send(:gs_getter_setter, :line_width, :w, nil))
      assert_operators(@page.contents, [])
    end

    it "always saves and restores the graphics state if a block is used" do
      @canvas.send(:gs_getter_setter, :line_width, :w,
                   @canvas.send(:gs_getter_setter, :line_width, :w, nil)) {}
      assert_operators(@page.contents, [[:save_graphics_state], [:restore_graphics_state]])
    end

    it "is serialized correctly when no block is used" do
      @canvas.send(:gs_getter_setter, :line_width, :w, 5)
      assert_operators(@page.contents, [[:set_line_width, [5]]])
    end

    it "is serialized correctly when a block is used" do
      @canvas.send(:gs_getter_setter, :line_width, :w, 5) do
        @canvas.send(:gs_getter_setter, :line_width, :w, 15)
      end
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:set_line_width, [5]],
                                        [:set_line_width, [15]],
                                        [:restore_graphics_state]])
    end

    it "fails if a block is given without an argument" do
      assert_raises(ArgumentError) { @canvas.send(:gs_getter_setter, :line_width, :w, nil) {} }
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) do
        @canvas.send(:gs_getter_setter, :line_width, :w, 5)
      end
    end
  end

  # Asserts that the method +name+ invoked with +values+ invokes the #gs_getter_setter helper method
  # with the +name+, +operator+ and +expected_value+ as arguments.
  def assert_gs_getter_setter(name, operator, expected_value, *values)
    args = [name, operator, expected_value]
    assert_method_invoked(@canvas, :gs_getter_setter, args, check_block: true) do
      @canvas.send(name, *values) {}
    end
    unless values.compact.empty?
      @canvas.send(name, *values)
      assert_equal(expected_value, @canvas.graphics_state.send(name))
    end
    assert_respond_to(@canvas, name)
  end

  describe "line_width" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:line_width, :w, 5, 5)
      assert_gs_getter_setter(:line_width, :w, nil, nil)
    end
  end

  describe "line_cap_style" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:line_cap_style, :J, 1, :round)
      assert_gs_getter_setter(:line_cap_style, :J, nil, nil)
    end
  end

  describe "line_join_style" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:line_join_style, :j, 1, :round)
      assert_gs_getter_setter(:line_join_style, :j, nil, nil)
    end
  end

  describe "miter_limit" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:miter_limit, :M, 15, 15)
      assert_gs_getter_setter(:miter_limit, :M, nil, nil)
    end
  end

  describe "line_dash_pattern" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:line_dash_pattern, :d, nil, nil)
      assert_gs_getter_setter(:line_dash_pattern, :d,
                              HexaPDF::Content::LineDashPattern.new, 0)
      assert_gs_getter_setter(:line_dash_pattern, :d,
                              HexaPDF::Content::LineDashPattern.new([5]), 5)
      assert_gs_getter_setter(:line_dash_pattern, :d,
                              HexaPDF::Content::LineDashPattern.new([5], 2), 5, 2)
      assert_gs_getter_setter(:line_dash_pattern, :d,
                              HexaPDF::Content::LineDashPattern.new([5, 3], 2), [5, 3], 2)
      assert_gs_getter_setter(:line_dash_pattern, :d,
                              HexaPDF::Content::LineDashPattern.new([5, 3], 2),
                              HexaPDF::Content::LineDashPattern.new([5, 3], 2))
    end
  end

  describe "rendering_intent" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:rendering_intent, :ri, :Perceptual, :Perceptual)
      assert_gs_getter_setter(:rendering_intent, :ri, nil, nil)
    end
  end

  describe "opacity" do
    it "returns the current values when no argument/nil arguments are provided" do
      assert_equal({fill_alpha: 1.0, stroke_alpha: 1.0}, @canvas.opacity)
    end

    it "returns the canvas object when at least one non-nil argument is provided" do
      assert_equal(@canvas, @canvas.opacity(fill_alpha: 0.5))
    end

    it "invokes the operator implementation when at least one non-nil argument is used" do
      assert_operator_invoked(:gs, :GS1) do
        @canvas.opacity(fill_alpha: 1.0, stroke_alpha: 0.5)
      end
    end

    it "doesn't add an operator if the values are not really changed" do
      @canvas.opacity(fill_alpha: 1.0, stroke_alpha: 1.0)
      assert_operators(@page.contents, [])
    end

    it "always saves and restores the graphics state if a block is used" do
      @canvas.opacity(fill_alpha: 1.0, stroke_alpha: 1.0) {}
      assert_operators(@page.contents, [[:save_graphics_state], [:restore_graphics_state]])
    end

    it "adds the needed entry to the /ExtGState resources dictionary" do
      @canvas.graphics_state.alpha_source = true
      @canvas.opacity(fill_alpha: 0.5, stroke_alpha: 0.7)
      assert_equal({Type: :ExtGState, CA: 0.7, ca: 0.5, AIS: false},
                   @canvas.resources.ext_gstate(:GS1))
    end

    it "is serialized correctly when no block is used" do
      @canvas.opacity(fill_alpha: 0.5, stroke_alpha: 0.7)
      assert_operators(@page.contents, [[:set_graphics_state_parameters, [:GS1]]])
    end

    it "is serialized correctly when a block is used" do
      @canvas.opacity(fill_alpha: 0.5) do
        @canvas.opacity(stroke_alpha: 0.7)
      end
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:set_graphics_state_parameters, [:GS1]],
                                        [:set_graphics_state_parameters, [:GS2]],
                                        [:restore_graphics_state]])
    end

    it "fails if a block is given without an argument" do
      assert_raises(ArgumentError) { @canvas.opacity {} }
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) { @canvas.opacity(fill_alpha: 1.0) }
    end
  end

  describe "private color_getter_setter" do
    def invoke(*params, &block)
      @canvas.send(:color_getter_setter, :stroke_color, params, :RG, :G, :K, :CS, :SCN, &block)
    end

    it "returns the current value when used with no argument" do
      color = @canvas.graphics_state.stroke_color
      assert_equal(color, invoke)
    end

    it "returns the canvas when used with a non-nil argument and no block" do
      assert_equal(@canvas, invoke(255))
      assert_equal(@canvas, invoke(255) {})
    end

    it "doesn't add an operator if the value is equal to the current one" do
      invoke(0.0)
      assert_operators(@page.contents, [])
    end

    it "always saves and restores the graphics state if a block is used" do
      invoke(0.0) {}
      assert_operators(@page.contents, [[:save_graphics_state], [:restore_graphics_state]])
    end

    it "adds an unknown color space to the resource dictionary" do
      invoke(HexaPDF::Content::ColorSpace::Universal.new([:Pattern, :DeviceRGB]).color(:Name))
      assert_equal([:Pattern, :DeviceRGB], @page.resources.color_space(:CS1).definition)
    end

    it "is serialized correctly when no block is used" do
      invoke(102)
      invoke([102])
      invoke("6600FF")
      invoke(102, 0, 255)
      invoke(0, 20, 40, 80)
      invoke(HexaPDF::Content::ColorSpace::Universal.new([:Pattern]).color(:Name))
      assert_operators(@page.contents, [[:set_device_gray_stroking_color, [0.4]],
                                        [:set_device_rgb_stroking_color, [0.4, 0, 1]],
                                        [:set_device_cmyk_stroking_color, [0, 0.2, 0.4, 0.8]],
                                        [:set_stroking_color_space, [:CS1]],
                                        [:set_stroking_color, [:Name]]])
    end

    it "is serialized correctly when a block is used" do
      invoke(102) { invoke(255) }
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:set_device_gray_stroking_color, [0.4]],
                                        [:set_device_gray_stroking_color, [1.0]],
                                        [:restore_graphics_state]])
    end

    it "fails if a block is given without an argument" do
      assert_raises(ArgumentError) { invoke {} }
    end

    it "fails if an unsupported number of component values is provided" do
      assert_raises(ArgumentError) { invoke(5, 5) }
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) { invoke(0.5) }
    end
  end

  # Asserts that the method +name+ invoked with +values+ invokes the #color_getter_setter helper
  # method with the +expected_values+ as arguments.
  def assert_color_getter_setter(name, expected_values, *values)
    assert_method_invoked(@canvas, :color_getter_setter, expected_values, check_block: true) do
      @canvas.send(name, *values) {}
    end
  end

  describe "stroke_color" do
    it "uses the color_getter_setter implementation" do
      assert_color_getter_setter(:stroke_color, [:stroke_color, [255], :RG, :G, :K, :CS, :SCN], 255)
      assert_color_getter_setter(:stroke_color, [:stroke_color, [], :RG, :G, :K, :CS, :SCN])
    end
  end

  describe "fill_color" do
    it "uses the color_getter_setter implementation" do
      assert_color_getter_setter(:fill_color, [:fill_color, [255], :rg, :g, :k, :cs, :scn], 255)
      assert_color_getter_setter(:fill_color, [:fill_color, [], :rg, :g, :k, :cs, :scn])
    end
  end

  describe "move_to" do
    it "invokes the operator implementation" do
      assert_operator_invoked(:m, 5, 6) { @canvas.move_to(5, 6) }
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.move_to(5, 6))
    end

    it "sets the current point correctly" do
      @canvas.move_to(5, 6)
      assert_equal([5, 6], @canvas.current_point)
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:clipping_path) { @canvas.move_to(5, 6) }
    end
  end

  describe "line_to" do
    before do
      @canvas.graphics_object = :path
    end

    it "invokes the operator implementation" do
      assert_operator_invoked(:l, 5, 6) { @canvas.line_to(5, 6) }
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.line_to(5, 6))
    end

    it "sets the current point correctly" do
      @canvas.line_to(5, 6)
      assert_equal([5, 6], @canvas.current_point)
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:none, :text, :clipping_path) { @canvas.line_to(5, 6) }
    end
  end

  describe "curve_to" do
    before do
      @canvas.graphics_object = :path
    end

    it "invokes the operator implementation" do
      assert_operator_invoked(:c, 5, 6, 7, 8, 9, 10) { @canvas.curve_to(9, 10, p1: [5, 6], p2: [7, 8]) }
      assert_operator_invoked(:v, 7, 8, 9, 10) { @canvas.curve_to(9, 10, p2: [7, 8]) }
      assert_operator_invoked(:y, 5, 6, 9, 10) { @canvas.curve_to(9, 10, p1: [5, 6]) }
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.curve_to(5, 6, p1: [7, 8]))
    end

    it "sets the current point correctly" do
      @canvas.curve_to(5, 6, p1: [9, 10])
      assert_equal([5, 6], @canvas.current_point)
    end

    it "raises an error if both control points are omitted" do
      assert_raises(ArgumentError) { @canvas.curve_to(9, 10) }
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:none, :text, :clipping_path) do
        @canvas.curve_to(5, 6, p1: [7, 8])
      end
    end
  end

  describe "rectangle" do
    it "invokes the operator implementation when radius == 0" do
      assert_operator_invoked(:re, 5, 10, 15, 20) { @canvas.rectangle(5, 10, 15, 20) }
    end

    it "invokes the polygon method when radius != 0" do
      args = [0, 0, 10, 0, 10, 10, 0, 10, {radius: 5}]
      assert_method_invoked(@canvas, :polygon, args) do
        @canvas.rectangle(0, 0, 10, 10, radius: 5)
      end
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.rectangle(5, 6, 7, 8))
    end

    it "sets the current point correctly" do
      @canvas.rectangle(5, 6, 7, 8)
      assert_equal([5, 6], @canvas.current_point)
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:clipping_path) { @canvas.rectangle(5, 6, 7, 8) }
    end
  end

  describe "close_subpath" do
    before do
      @canvas.graphics_object = :path
    end

    it "invokes the operator implementation" do
      assert_operator_invoked(:h) { @canvas.close_subpath }
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.close_subpath)
    end

    it "sets the current point correctly" do
      @canvas.move_to(1, 1)
      @canvas.line_to(10, 10)
      @canvas.close_subpath
      assert_equal([1, 1], @canvas.current_point)
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:none, :text) { @canvas.close_subpath }
    end
  end

  describe "line" do
    it "serializes correctly" do
      @canvas.line(1, 2, 3, 4)
      assert_operators(@canvas.contents, [[:move_to, [1, 2]], [:line_to, [3, 4]]])
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.line(1, 2, 3, 4))
    end
  end

  describe "polyline" do
    it "serializes correctly" do
      @canvas.polyline(1, 2, 3, 4, 5, 6)
      assert_operators(@canvas.contents, [[:move_to, [1, 2]], [:line_to, [3, 4]], [:line_to, [5, 6]]])
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.polyline(1, 2, 3, 4))
    end

    it "fails if not enought points are supplied" do
      assert_raises(ArgumentError) { @canvas.polyline(5, 6) }
    end

    it "fails if a y-coordinate is missing" do
      assert_raises(ArgumentError) { @canvas.polyline(5, 6, 7, 8, 9) }
    end
  end

  describe "polygon" do
    it "serializes correctly with no radius" do
      @canvas.polygon(1, 2, 3, 4, 5, 6)
      assert_operators(@canvas.contents, [[:move_to, [1, 2]], [:line_to, [3, 4]],
                                          [:line_to, [5, 6]], [:close_subpath]])
    end

    it "serializes correctly with a radius" do
      @canvas.polygon(-1, -1, -1, 1, 1, 1, 1, -1, radius: 1)
      k = @canvas.class::KAPPA.round(6)
      assert_operators(@canvas.contents, [[:move_to, [-1, 0]],
                                          [:line_to, [-1, 0]], [:curve_to, [-1, k, -k, 1, 0, 1]],
                                          [:line_to, [0, 1]], [:curve_to, [k, 1, 1, k, 1, 0]],
                                          [:line_to, [1, 0]], [:curve_to, [1, -k, k, -1, 0, -1]],
                                          [:line_to, [0, -1]], [:curve_to, [-k, -1, -1, -k, -1, 0]],
                                          [:close_subpath]])
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.polyline(1, 2, 3, 4, 5, 6))
    end
  end

  describe "circle" do
    it "uses arc for the hard work" do
      assert_method_invoked(@canvas, :arc, [5, 6, {a: 7}]) do
        @canvas.graphics_object = :path
        @canvas.circle(5, 6, 7)
      end
    end

    it "serializes correctly" do
      @canvas.circle(0, 0, 1)
      assert_operators(@canvas.contents,
                       [:move_to, :curve_to, :curve_to, :curve_to, :curve_to, :close_subpath],
                       only_names: true)
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.circle(1, 2, 3))
    end
  end

  describe "ellipse" do
    it "uses arc for the hard work" do
      assert_method_invoked(@canvas, :ellipse, [5, 6, {a: 7, b: 5, inclination: 10}]) do
        @canvas.ellipse(5, 6, a: 7, b: 5, inclination: 10)
      end
    end

    it "serializes correctly" do
      @canvas.ellipse(0, 0, a: 10, b: 5, inclination: 10)
      assert_operators(@canvas.contents,
                       [:move_to, :curve_to, :curve_to, :curve_to, :curve_to, :close_subpath],
                       only_names: true)
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.circle(1, 2, 3))
    end
  end

  describe "arc" do
    it "serializes correctly" do
      @canvas.arc(0, 0, a: 1, b: 1, start_angle: 0, end_angle: 360, inclination: 0)
      @canvas.arc(0, 0, a: 1, b: 1, start_angle: 0, end_angle: 360, clockwise: true, inclination: 0)
      assert_operators(@canvas.contents, [[:move_to, [1, 0]],
                                          [:curve_to, [1, 0.548584, 0.548584, 1, 0, 1]],
                                          [:curve_to, [-0.548584, 1, -1, 0.548584, -1, 0]],
                                          [:curve_to, [-1, -0.548584, -0.548584, -1, 0, -1]],
                                          [:curve_to, [0.548584, -1, 1, -0.548584, 1, 0]],
                                          [:move_to, [1, 0]],
                                          [:curve_to, [1, -0.548584, 0.548584, -1, 0, -1]],
                                          [:curve_to, [-0.548584, -1, -1, -0.548584, -1, 0]],
                                          [:curve_to, [-1, 0.548584, -0.548584, 1, 0, 1]],
                                          [:curve_to, [0.548584, 1, 1, 0.548584, 1, 0]]])
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.arc(1, 2, a: 3))
    end
  end

  describe "line_with_rounded_corner" do
    it "serializes correctly" do
      @canvas.move_to(10, 10)
      @canvas.line_with_rounded_corner(30, 10, 30, 50, in_radius: 10, out_radius: 5)
      @canvas.line_with_rounded_corner(30, 50, 30, 10, 30, 50, in_radius: 10, out_radius: 5)
      assert_operators(@canvas.contents,
                       [[:move_to, [10, 10]],
                        [:line_to, [20, 10]],
                        [:curve_to, [25.51915, 10.0, 30.0, 12.240425, 30.0, 15.0]],
                        [:line_to, [30, 20]],
                        [:curve_to, [30.0, 14.48085, 30.0, 12.240425, 30.0, 15.0]]])
    end

    describe "degraded cases" do
      it "p0 equal p1" do
        @canvas.move_to(10, 10)
        @canvas.line_with_rounded_corner(10, 10, 10, 20, in_radius: 5)
        assert_operators(@canvas.contents,
                         [[:move_to, [10, 10]],
                          [:line_to, [10, 10]]])
      end

      it "p1 equal p2" do
        @canvas.move_to(10, 10)
        @canvas.line_with_rounded_corner(20, 10, 20, 10, in_radius: 5)
        assert_operators(@canvas.contents,
                         [[:move_to, [10, 10]],
                          [:line_to, [20, 10]]])
      end

      it "p0 equal p1 equal p2" do
        @canvas.move_to(10, 10)
        @canvas.line_with_rounded_corner(10, 10, 10, 10, in_radius: 5)
        assert_operators(@canvas.contents,
                         [[:move_to, [10, 10]],
                          [:line_to, [10, 10]]])
      end

      it "in_radius = 0" do
        @canvas.move_to(10, 10)
        @canvas.line_with_rounded_corner(20, 10, 20, 20, in_radius: 0, out_radius: 5)
        assert_operators(@canvas.contents,
                         [[:move_to, [10, 10]],
                          [:line_to, [20, 10]]])
      end

      it "out_radius = 0" do
        @canvas.move_to(10, 10)
        @canvas.line_with_rounded_corner(20, 10, 20, 20, in_radius: 5, out_radius: 0)
        assert_operators(@canvas.contents,
                         [[:move_to, [10, 10]],
                          [:line_to, [20, 10]]])
      end
    end

    it "returns the canvas object" do
      @canvas.move_to(10, 10)
      assert_equal(@canvas, @canvas.line_with_rounded_corner(30, 30, 30, 50, in_radius: 10))
    end
  end

  describe "form" do
    it "uses the context dimensions if none are given" do
      form = @canvas.form
      assert_equal(@canvas.context.box.value, form.box.value)
    end

    it "uses the provided dimensions" do
      form = @canvas.form(300, 200)
      assert_equal([0, 0, 300, 200], form.box.value)
    end

    it "yields the canvas for defining the form's content" do
      yielded_canvas = nil
      form = @canvas.form {|canvas| yielded_canvas = canvas }
      assert_equal(form.canvas, yielded_canvas)
    end

    it "raises an ArgumentError if only one of width/height is provided" do
      assert_raises(ArgumentError) { @canvas.form(20) }
    end
  end

  describe "graphic_object" do
    it "returns a new graphic object given a name" do
      arc = @canvas.graphic_object(:arc)
      assert_respond_to(arc, :draw)
      arc1 = @canvas.graphic_object(:arc)
      refute_same(arc, arc1)
    end

    it "returns a configured graphic object given a name" do
      arc = @canvas.graphic_object(:arc, cx: 10)
      assert_equal(10, arc.cx)
    end

    it "reconfigures the given graphic object" do
      arc = @canvas.graphic_object(:arc)
      arc1 = @canvas.graphic_object(arc, cx: 10)
      assert_same(arc, arc1)
      assert_equal(10, arc.cx)
    end
  end

  describe "draw" do
    it "draws the, optionally configured, graphic object onto the canvas" do
      obj = Object.new
      obj.define_singleton_method(:options) { @options }
      obj.define_singleton_method(:configure) {|**kwargs| @options = kwargs; self }
      obj.define_singleton_method(:draw) {|canvas| canvas.move_to(@options[:x], @options[:y]) }
      @canvas.draw(obj, x: 5, y: 6)
      assert_operators(@canvas.contents, [[:move_to, [5, 6]]])
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.draw(:arc))
    end
  end

  describe "path painting methods" do
    before do
      @canvas.graphics_object = :path
    end

    it "invokes the respective operator implementation" do
      assert_operator_invoked(:S) { @canvas.stroke }
      assert_operator_invoked(:s) { @canvas.close_stroke }
      assert_operator_invoked(:f) { @canvas.fill(:nonzero) }
      assert_operator_invoked(:'f*') { @canvas.fill(:even_odd) }
      assert_operator_invoked(:B) { @canvas.fill_stroke(:nonzero) }
      assert_operator_invoked(:'B*') { @canvas.fill_stroke(:even_odd) }
      assert_operator_invoked(:b) { @canvas.close_fill_stroke(:nonzero) }
      assert_operator_invoked(:'b*') { @canvas.close_fill_stroke(:even_odd) }
      assert_operator_invoked(:n) { @canvas.end_path }
    end

    it "returns the canvas object" do
      [:stroke, :close_stroke, :fill, :fill_stroke, :close_fill_stroke, :end_path].each do |m|
        @canvas.graphics_object = :path
        assert_equal(@canvas, @canvas.send(m))
      end
    end

    it "fails if invoked while in an unsupported graphics objects" do
      [:stroke, :close_stroke, :fill, :fill_stroke, :close_fill_stroke, :end_path].each do |m|
        assert_raises_in_graphics_object(:none, :text) { @canvas.send(m) }
      end
    end
  end

  describe "clip_path" do
    before do
      @canvas.graphics_object = :path
    end

    it "invokes the respective operator implementation" do
      assert_operator_invoked(:W) { @canvas.clip_path(:nonzero) }
      assert_operator_invoked(:'W*') { @canvas.clip_path(:even_odd) }
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.clip_path)
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:none, :text, :clipping_path) { @canvas.clip_path }
    end
  end

  describe "xobject" do
    before do
      @image = @doc.add({Type: :XObject, Subtype: :Image, Width: 10, Height: 5})
      @image.source_path = File.join(TEST_DATA_DIR, 'images', 'gray.jpg')
      @form = @doc.add({Type: :XObject, Subtype: :Form, BBox: [100, 50, 200, 100]})
    end

    it "can use any xobject specified via a filename" do
      xobject = @canvas.xobject(@image.source_path, at: [0, 0])
      assert_equal(xobject, @page.resources.xobject(:XO1))
    end

    it "can use any xobject specified via an IO object" do
      File.open(@image.source_path, 'rb') do |file|
        xobject = @canvas.xobject(file, at: [0, 0])
        assert_equal(xobject, @page.resources.xobject(:XO1))
      end
    end

    it "can use an already existing xobject" do
      xobject = @canvas.xobject(@image, at: [0, 0])
      assert_equal(xobject, @page.resources.xobject(:XO1))
    end

    it "correctly serializes the image with no options" do
      @canvas.xobject(@image, at: [1, 2])
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [10, 0, 0, 5, 1, 2]],
                                        [:paint_xobject, [:XO1]],
                                        [:restore_graphics_state]])
    end

    it "correctly serializes the image with just the width given" do
      @canvas.image(@image, at: [1, 2], width: 20)
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [20, 0, 0, 10, 1, 2]],
                                        [:paint_xobject, [:XO1]],
                                        [:restore_graphics_state]])
    end

    it "correctly serializes the image with just the height given" do
      @canvas.image(@image, at: [1, 2], height: 10)
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [20, 0, 0, 10, 1, 2]],
                                        [:paint_xobject, [:XO1]],
                                        [:restore_graphics_state]])
    end

    it "correctly serializes the image with both width and height given" do
      @canvas.image(@image, at: [1, 2], width: 10, height: 20)
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [10, 0, 0, 20, 1, 2]],
                                        [:paint_xobject, [:XO1]],
                                        [:restore_graphics_state]])
    end

    it "doesn't do anything if the image's width or height is zero" do
      @image[:Width] = 0
      @canvas.xobject(@image, at: [0, 0])
      assert_operators(@page.contents, [])

      @image[:Width] = 10
      @image[:Height] = 0
      @canvas.xobject(@image, at: [0, 0])
      assert_operators(@page.contents, [])
    end

    it "correctly serializes the form with no options" do
      @canvas.xobject(@form, at: [1, 2])
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [1, 0, 0, 1, -99, -48]],
                                        [:paint_xobject, [:XO1]],
                                        [:restore_graphics_state]])
    end

    it "correctly serializes the form with just the width given" do
      @canvas.image(@form, at: [1, 2], width: 50)
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [0.5, 0, 0, 0.5, -99, -48]],
                                        [:paint_xobject, [:XO1]],
                                        [:restore_graphics_state]])
    end

    it "correctly serializes the form with just the height given" do
      @canvas.image(@form, at: [1, 2], height: 10)
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [0.2, 0, 0, 0.2, -99, -48]],
                                        [:paint_xobject, [:XO1]],
                                        [:restore_graphics_state]])
    end

    it "correctly serializes the form with both width and height given" do
      @canvas.image(@form, at: [1, 2], width: 50, height: 10)
      assert_operators(@page.contents, [[:save_graphics_state],
                                        [:concatenate_matrix, [0.5, 0, 0, 0.2, -99, -48]],
                                        [:paint_xobject, [:XO1]],
                                        [:restore_graphics_state]])
    end

    it "correctly serializes the form when no transformation is needed" do
      @canvas.image(@form, at: [100, 50])
      assert_operators(@page.contents, [[:paint_xobject, [:XO1]]])
    end

    it "doesn't do anything if the form's width or height is zero" do
      @form[:BBox] = [100, 50, 100, 200]
      @canvas.xobject(@form, at: [0, 0])
      assert_operators(@page.contents, [])

      @form[:BBox] = [100, 50, 150, 50]
      @canvas.xobject(@form, at: [0, 0])
      assert_operators(@page.contents, [])
    end
  end

  describe "character_spacing" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:character_spacing, :Tc, 0.25, 0.25)
      assert_gs_getter_setter(:character_spacing, :Tc, nil, nil)
    end
  end

  describe "word_spacing" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:word_spacing, :Tw, 0.25, 0.25)
      assert_gs_getter_setter(:word_spacing, :Tw, nil, nil)
    end
  end

  describe "horizontal_scaling" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:horizontal_scaling, :Tz, 50, 50)
      assert_gs_getter_setter(:horizontal_scaling, :Tz, nil, nil)
    end
  end

  describe "leading" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:leading, :TL, 15, 15)
      assert_gs_getter_setter(:leading, :TL, nil, nil)
    end
  end

  describe "text_rendering_mode" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:text_rendering_mode, :Tr, 0, :fill)
      assert_gs_getter_setter(:text_rendering_mode, :Tr, nil, nil)
    end
  end

  describe "text_rise" do
    it "uses the gs_getter_setter implementation" do
      assert_gs_getter_setter(:text_rise, :Ts, 15, 15)
      assert_gs_getter_setter(:text_rise, :Ts, nil, nil)
    end
  end

  describe "begin_text" do
    it "invokes the operator implementation" do
      assert_operator_invoked(:BT) { @canvas.begin_text }
    end

    it "serializes correctly" do
      @canvas.begin_text
      @canvas.begin_text
      @canvas.begin_text(force_new: true)
      assert_operators(@canvas.contents, [:begin_text, :end_text, :begin_text], only_names: true)
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.begin_text)
    end

    it "fails if the current graphics object doesn't allow a new text object" do
      assert_raises(HexaPDF::Error) do
        @canvas.graphics_object = :path
        @canvas.begin_text
      end
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) { @canvas.begin_text }
    end
  end

  describe "end_text" do
    it "invokes the operator implementation" do
      @canvas.graphics_object = :text
      assert_operator_invoked(:ET) { @canvas.end_text }
    end

    it "serializes correctly" do
      @canvas.end_text
      @canvas.begin_text
      @canvas.end_text
      @canvas.end_text
      assert_operators(@page.contents, [:begin_text, :end_text], only_names: true)
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.begin_text)
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) { @canvas.end_text }
    end
  end

  describe "text_matrix" do
    it "invokes the operator implementation" do
      @canvas.text_matrix(1, 2, 3, 4, 5, 6)
      assert_operators(@canvas.contents, [[:begin_text],
                                          [:set_text_matrix, [1, 2, 3, 4, 5, 6]]])
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.text_matrix(1, 1, 1, 1, 1, 1))
    end
  end

  describe "move_text_cursor" do
    describe "invokes the operator implementation" do
      it "moves to the next line" do
        @canvas.move_text_cursor
        assert_operators(@canvas.contents, [[:begin_text],
                                            [:move_text_next_line]])
      end

      it "moves to the next line with an offset" do
        @canvas.move_text_cursor(offset: [5, 10], absolute: false)
        assert_operators(@canvas.contents, [[:begin_text],
                                            [:move_text, [5, 10]]])
      end

      it "moves to an absolute position" do
        @canvas.move_text_cursor(offset: [5, 10], absolute: true)
        assert_operators(@canvas.contents, [[:begin_text],
                                            [:set_text_matrix, [1, 0, 0, 1, 5, 10]]])
      end
    end

    it "returns the canvas object" do
      assert_equal(@canvas, @canvas.move_text_cursor)
    end
  end

  describe "text_cursor" do
    it "returns the text cursor position" do
      @canvas.move_text_cursor(offset: [5, 10])
      assert_equal([5, 10], @canvas.text_cursor)
    end

    it "fails if invoked outside a text object" do
      assert_raises_in_graphics_object(:none, :path, :clipping_path) { @canvas.text_cursor }
    end
  end

  describe "font" do
    it "returns the set font" do
      assert_nil(@canvas.font)
      @canvas.font("Times", size: 10)
      assert_same(@doc.fonts.add("Times"), @canvas.font)
      @canvas.font(@canvas.font)
      assert_same(@doc.fonts.add("Times"), @canvas.font)
      @canvas.font("Helvetica", size: 10)
      assert_operators(@canvas.contents, [[:set_font_and_size, [:F1, 10]],
                                          [:set_font_and_size, [:F2, 10]]])
    end

    it "sets the font and optionally the font size" do
      @canvas.font("Times", size: 12, variant: :italic)
      assert_same(@doc.fonts.add("Times", variant: :italic), @canvas.font)
      assert_equal(12, @canvas.font_size)
      @canvas.font("Helvetica")
      assert_equal(12, @canvas.font_size)
    end
  end

  describe "font_size" do
    it "returns the set font size" do
      assert_equal(0, @canvas.font_size)
      @canvas.font("Times", size: 10) # calls #font_size
      assert_equal(10, @canvas.font_size)
    end

    it "sets the font size" do
      @canvas.font("Times", size: 10)
      assert_equal(10, @canvas.font_size)
    end

    it "fails if no valid font is already set" do
      assert_raises(HexaPDF::Error) { @canvas.font_size(10) }
    end
  end

  describe "show_glyphs" do
    it "serializes correctly" do
      @canvas.font("Times", size: 20)
      @canvas.horizontal_scaling(200)
      @canvas.character_spacing(1)
      @canvas.word_spacing(2)

      font = @canvas.font
      @canvas.show_glyphs(font.decode_utf8("Hal lo").insert(2, -35).insert(0, -10))
      assert_in_delta(116.68, @canvas.text_cursor[0])
      assert_equal(0, @canvas.text_cursor[1])
      @canvas.font_size(10)
      @canvas.show_glyphs(font.decode_utf8("Hal"))
      assert_operators(@canvas.contents, [[:set_font_and_size, [:F1, 20]],
                                          [:set_horizontal_scaling, [200]],
                                          [:set_character_spacing, [1]],
                                          [:set_word_spacing, [2]],
                                          [:begin_text],
                                          [:show_text_with_positioning, [['', -10, "Ha", -35, "l lo"]]],
                                          [:set_font_and_size, [:F1, 10]],
                                          [:show_text_with_positioning, [["Hal"]]]])
    end

    it "does nothing if there are no glyphs" do
      @canvas.show_glyphs_only([])
      assert_operators(@canvas.contents, [])
    end
  end

  describe "show_glyphs_only" do
    it "serializes positioned glyphs correctly" do
      @canvas.font("Times", size: 20)
      font = @canvas.font
      @canvas.show_glyphs_only(font.decode_utf8("Hal lo").insert(2, -35))
      assert_equal(0, @canvas.text_cursor[0])
      assert_equal(0, @canvas.text_cursor[1])
      assert_operators(@canvas.contents, [[:set_font_and_size, [:F1, 20]],
                                          [:begin_text],
                                          [:show_text_with_positioning, [["Ha", -35, "l lo"]]]])
    end

    it "serializes unpositioned glyphs correctly" do
      @canvas.font("Times", size: 20)
      font = @canvas.font
      @canvas.show_glyphs_only(font.decode_utf8("Hallo"))
      assert_operators(@canvas.contents, [[:set_font_and_size, [:F1, 20]],
                                          [:begin_text],
                                          [:show_text, ["Hallo"]]])
    end

    it "does nothing if there are no glyphs" do
      @canvas.show_glyphs_only([])
      assert_operators(@canvas.contents, [])
    end
  end

  describe "text" do
    it "sets the text cursor position if instructed" do
      @canvas.font("Times", size: 10)
      @canvas.text("Hallo", at: [100, 100])
      assert_operators(@canvas.contents, [[:set_font_and_size, [:F1, 10]],
                                          [:begin_text],
                                          [:set_text_matrix, [1, 0, 0, 1, 100, 100]],
                                          [:show_text_with_positioning, [["Hallo"]]]])
    end

    it "shows text, possibly split over multiple lines" do
      @canvas.font("Times", size: 10)
      @canvas.text("H\u{D A}H\u{A}H\u{B}H\u{c}H\u{D}H\u{85}H\u{2028}H\u{2029}H")
      assert_operators(@canvas.contents, [[:set_font_and_size, [:F1, 10]],
                                          [:set_leading, [10]],
                                          [:begin_text],
                                          [:show_text_with_positioning, [["H"]]], [:move_text_next_line],
                                          [:show_text_with_positioning, [["H"]]], [:move_text_next_line],
                                          [:show_text_with_positioning, [["H"]]], [:move_text_next_line],
                                          [:show_text_with_positioning, [["H"]]], [:move_text_next_line],
                                          [:show_text_with_positioning, [["H"]]], [:move_text_next_line],
                                          [:show_text_with_positioning, [["H"]]], [:move_text_next_line],
                                          [:show_text_with_positioning, [["H"]]], [:move_text_next_line],
                                          [:show_text_with_positioning, [["H"]]], [:move_text_next_line],
                                          [:show_text_with_positioning, [["H"]]]])
    end

    it "fails if no valid font is set" do
      error = assert_raises(HexaPDF::Error) { @canvas.text("test") }
      assert_match(/if a font is set/, error.message)
    end
  end

  describe "marked_content_point" do
    it "invokes the operator implementation" do
      assert_operator_invoked(:MP, :tag) { @canvas.marked_content_point(:tag) }
      assert_operator_invoked(:DP, :tag, :P1) do
        @canvas.marked_content_point(:tag, property_list: {key: 5})
      end
    end

    it "is serialized correctly" do
      @canvas.marked_content_point(:tag)
      assert_operators(@canvas.contents, [[:designate_marked_content_point, [:tag]]])
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) { @canvas.marked_content_point(:tag) }
    end
  end

  describe "marked_content_sequence" do
    it "invokes the operator implementation" do
      assert_operator_invoked(:BMC, :tag) { @canvas.marked_content_sequence(:tag) }
      assert_operator_invoked(:BDC, :tag, :P1) do
        @canvas.marked_content_sequence(:tag, property_list: {key: 5})
      end
    end

    it "is serialized correctly when no block is used" do
      @canvas.marked_content_sequence(:tag)
      assert_operators(@canvas.contents, [[:begin_marked_content, [:tag]]])
    end

    it "is serialized correctly when a block is used" do
      @canvas.marked_content_sequence(:tag, property_list: {key: 5}) {}
      assert_operators(@canvas.contents, [[:begin_marked_content_with_property_list, [:tag, :P1]],
                                          [:end_marked_content]])
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) do
        @canvas.marked_content_sequence(:tag)
      end
    end
  end

  describe "end_marked_content_sequence" do
    it "invokes the operator implementation" do
      assert_operator_invoked(:EMC) { @canvas.end_marked_content_sequence }
    end

    it "is serialized correctly" do
      @canvas.end_marked_content_sequence
      assert_operators(@page.contents, [[:end_marked_content]])
    end

    it "fails if invoked while in an unsupported graphics objects" do
      assert_raises_in_graphics_object(:path, :clipping_path) do
        @canvas.end_marked_content_sequence
      end
    end
  end

  describe "optional_content" do
    it "invokes the marked-sequence operator implementation" do
      assert_operator_invoked(:BDC, :OC, :P1) { @canvas.optional_content('Test') }
    end

    it "is serialized correctly when no block is used" do
      @canvas.optional_content('Test')
      assert_operators(@canvas.contents, [[:begin_marked_content_with_property_list, [:OC, :P1]]])
    end

    it "is serialized correctly when a block is used" do
      @canvas.optional_content('Test') {}
      assert_operators(@canvas.contents, [[:begin_marked_content_with_property_list, [:OC, :P1]],
                                          [:end_marked_content]])
    end

    it "uses the provided OCG dictionary" do
      ocg = @doc.optional_content.add_ocg('Test')
      @canvas.optional_content(ocg)
      assert_equal(ocg, @page.resources.property_list(:P1))
    end

    it "uses an existing OCG specified by name" do
      ocg = @doc.optional_content.add_ocg('Test')
      @canvas.optional_content('Test')
      assert_equal(ocg, @page.resources.property_list(:P1))
    end

    it "creates an OCG if the named one doesn't yet exist" do
      @canvas.optional_content('Test')
      assert_equal(@doc.optional_content.ocg('Test'), @page.resources.property_list(:P1))
    end

    it "always creates a new OCG if use_existing_ocg is false" do
      ocg = @doc.optional_content.add_ocg('Test')
      @canvas.optional_content('Test', use_existing_ocg: false)
      pl_item = @page.resources.property_list(:P1)
      refute_equal(ocg, pl_item)
      assert_equal(@doc.optional_content.ocgs.last, pl_item)
    end
  end

  describe "composer" do
    it "creates a CanvasComposer, yields it and returns it" do
      comp1 = nil
      comp2 = @canvas.composer {|composer| comp1 = composer }
      assert_kind_of(HexaPDF::Content::CanvasComposer, comp1)
      assert_same(comp1, comp2)
      assert_same(@canvas, comp1.canvas)
    end

    it "passes on the margin argument" do
      comp = @canvas.composer(margin: 20)
      assert_equal(20, comp.frame.x)
    end
  end

  describe "color_from_specification " do
    it "accepts a color string" do
      assert_equal([1, 0, 0], @canvas.color_from_specification("red").components)
    end

    it "accepts a color string wrapped in an array" do
      assert_equal([1, 0, 0], @canvas.color_from_specification(["red"]).components)
    end

    it "accepts a color object" do
      color = @canvas.color_from_specification("red")
      assert_equal(color, @canvas.color_from_specification(color))
    end

    it "accepts a color object wrapped in an array" do
      color = @canvas.color_from_specification("red")
      assert_equal(color, @canvas.color_from_specification([color]))
    end

    it "accepts an array with 1, 3, or 4 color values" do
      assert_equal([1], @canvas.color_from_specification([255]).components)
      assert_equal([1, 0, 0], @canvas.color_from_specification([255, 0, 0]).components)
      assert_equal([1, 0, 0, 0], @canvas.color_from_specification([100, 0, 0, 0]).components)
    end
  end
end
