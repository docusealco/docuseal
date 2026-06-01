# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/configuration'
require 'hexapdf/document'

describe HexaPDF::Configuration do
  before do
    @config = HexaPDF::Configuration.new
    @config['test'] = :test
  end

  it "can create a config based on the default one with certain values overwritten" do
    config = HexaPDF::Configuration.with_defaults('io.chunk_size' => 10)
    assert_equal(10, config['io.chunk_size'])
    assert_equal(:A4, config['page.default_media_box'])
  end

  it "can check the availabilty of an option" do
    assert(@config.option?('test'))
  end

  it "can return the value for an option" do
    assert_equal(:test, @config['test'])
  end

  it "can set the value for an option" do
    @config['test'] = :other
    assert_equal(:other, @config['test'])
  end

  it "can create a new config object by merging another one or a hash" do
    @config['hash'] = {'test' => :test, 'other' => :other}
    @config['array'] = [5, 6]
    config = @config.merge('test' => :other)
    assert_equal(:other, config['test'])

    config['hash']['test'] = :other
    config1 = @config.merge(config)
    assert_equal(:other, config1['hash']['test'])
    assert_equal(:other, config1['hash']['other'])

    config2 = @config.merge(config)
    config2['array'].unshift(4)
    assert_equal([4, 5, 6], config2['array'])
    assert_equal([5, 6], config['array'])
  end

  describe "constantize" do
    it "returns a constant for an option with a string value" do
      @config['test'] = 'HexaPDF'
      assert_equal(HexaPDF, @config.constantize('test'))
    end

    it "returns a constant for an option with a constant as value" do
      @config['test'] = HexaPDF
      assert_equal(HexaPDF, @config.constantize('test'))
    end

    it "returns a constant for a nested option" do
      @config['test'] = {'test' => ['HexaPDF'], 'const' => {'const' => HexaPDF}}
      assert_equal(HexaPDF, @config.constantize('test', 'test', 0))
      assert_equal(HexaPDF, @config.constantize('test', 'const', 'const'))

      @config['test'] = ['HexaPDF', HexaPDF]
      assert_equal(HexaPDF, @config.constantize('test', 0))
      assert_equal(HexaPDF, @config.constantize('test', 1))
    end

    def assert_constantize_error(&block) # :nodoc:
      exp = assert_raises(HexaPDF::Error, &block)
      assert_match(/Error getting constant for configuration option/, exp.message)
    end

    it "raises an error for an unknown option" do
      assert_constantize_error { @config.constantize('unknown') }
    end

    it "raises an error for an unknown constant" do
      @config['test'] = 'SomeUnknownConstant'
      assert_constantize_error { @config.constantize('test') }
    end

    it "raises an error for an unknown constant using a nested option" do
      @config['test'] = {}
      assert_constantize_error { @config.constantize('test', 'test') }
      assert_constantize_error { @config.constantize('test', nil) }
    end

    it "returns the result of the given block when no constant is found" do
      assert_equal(:test, @config.constantize('unk') {|name| assert_equal('unk', name); :test })
    end
  end
end

describe "HexaPDF.font_on_invalid_glyph" do
  before do
    @doc = HexaPDF::Document.new
    @font = @doc.fonts.add('Helvetica')
  end

  def assert_glyph(font, codepoint, font_name, glyph_name)
    invalid_glyph = HexaPDF::Font::InvalidGlyph.new(font, codepoint.chr("UTF-8"))
    glyph = HexaPDF.font_on_invalid_glyph(codepoint, invalid_glyph)

    assert_equal(1, glyph.size)
    glyph = glyph.first
    assert(glyph.valid?)
    assert_equal(font_name, glyph.font_wrapper.wrapped_font.font_name)
    assert_equal(glyph_name, glyph.name)
    glyph
  end

  it "tries each fallback font and uses the first valid glyph" do
    assert_glyph(@font, 10102, "ZapfDingbats", :a130)
    assert_glyph(@font, 8855, "Symbol", :circlemultiply)
  end

  it "takes the font variant into account" do
    @doc.config['font.fallback'] = ['Times']

    glyph = assert_glyph(@doc.fonts.add("Helvetica", variant: :bold), 65, "Times-Bold", :A)
    assert(glyph.font_wrapper.bold?)

    glyph = assert_glyph(@doc.fonts.add("Helvetica", variant: :italic), 65, "Times-Italic", :A)
    assert(glyph.font_wrapper.italic?)

    glyph = assert_glyph(@doc.fonts.add("Helvetica", variant: :bold_italic), 65, "Times-BoldItalic", :A)
    assert(glyph.font_wrapper.bold?)
    assert(glyph.font_wrapper.italic?)
  end

  it "falls back to the :none variant of a fallback font if a more specific one doesn't exist" do
    assert_glyph(@doc.fonts.add("Helvetica", variant: :bold), 9985, "ZapfDingbats", :a1)
  end

  it "returns the given invalid glyph if no fallback glyph could be found" do
    @doc.config['font.fallback'] = []
    invalid_glyph = HexaPDF::Font::InvalidGlyph.new(@font, "A")
    assert_equal([invalid_glyph], HexaPDF.font_on_invalid_glyph(65, invalid_glyph))
  end
end
