# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/dictionary_fields'
require 'hexapdf/dictionary'
require 'hexapdf/stream'
require 'hexapdf/type'

describe HexaPDF::DictionaryFields do
  include HexaPDF::DictionaryFields

  describe "Field" do
    before do
      @field = self.class::Field.new([:Integer, self.class::PDFByteString], required: true,
                                     default: 500, indirect: false, allowed_values: [500, 1],
                                     version: '1.2')
      HexaPDF::GlobalConfiguration['object.type_map'][:Integer] = Integer
    end

    after do
      HexaPDF::GlobalConfiguration['object.type_map'].delete(:Integer)
    end

    it "allows access to the basic field information" do
      assert(@field.required?)
      assert(@field.default?)
      assert_equal(500, @field.default)
      assert_equal(false, @field.indirect)
      assert_equal('1.2', @field.version)
      assert_equal([500, 1], @field.allowed_values)
    end

    it "maps string types to constants" do
      assert_equal([Integer, self.class::PDFByteString, Hash, String], @field.type)
    end

    describe "convert" do
      it "returns the converted object, using the first usable converter" do
        doc = Minitest::Mock.new
        doc.expect(:wrap, :data, [Hash], type: Integer)
        @field.convert({}, doc)
        doc.verify

        assert(@field.convert('str', self).encoding == Encoding::BINARY)
      end

      it "returns nil for unconvertable objects" do
        assert_nil(@field.convert(5.5, self))
      end
    end

    it "can check for a valid object" do
      refute(@field.valid_object?(5.5))
      assert(@field.valid_object?(5))
      assert(@field.valid_object?(HexaPDF::Object.new(5)))
    end
  end

  describe "DictionaryConverter" do
    before do
      @field = self.class::Field.new(Class.new(HexaPDF::Dictionary))
      @doc = Minitest::Mock.new
    end

    it "additionally adds Hash as allowed type" do
      assert(@field.type.include?(Hash))
    end

    it "allows conversion from a hash" do
      @doc.expect(:wrap, :data, [Hash], type: Class)
      @field.convert({Test: :value}, @doc)
      @doc.verify
    end

    it "allows conversion from a Dictionary" do
      @doc.expect(:wrap, :data, [HexaPDF::Dictionary], type: Class)
      @field.convert(HexaPDF::Dictionary.new({Test: :value}), @doc)
      @doc.verify
    end

    it "allows conversion from an HexaPDF::Dictionary to a Stream if stream data is set" do
      @field = self.class::Field.new(HexaPDF::Stream)
      @doc.expect(:wrap, :data, [HexaPDF::Dictionary], type: Class)
      data = HexaPDF::PDFData.new({}, 0, 0, "")
      @field.convert(HexaPDF::Dictionary.new(data), @doc)
      @doc.verify
    end

    it "doesn't allow conversion to a Stream subclass from Hash or Dictionary" do
      @field = self.class::Field.new(HexaPDF::Stream)
      refute(@field.convert({}, @doc))
      refute(@field.convert(HexaPDF::Dictionary.new({Test: :value}), @doc))
    end

    it "doesn't allow conversion from nil" do
      refute(@field.convert(nil, @doc))
    end
  end

  describe "ArrayConverter" do
    before do
      @field = self.class::Field.new(HexaPDF::PDFArray)
      @doc = Minitest::Mock.new
    end

    it "additionally adds Array as allowed type" do
      assert(@field.type.include?(Array))
    end

    it "allows conversion from an array" do
      @doc.expect(:wrap, :data, [[1, 2]], type: HexaPDF::PDFArray)
      @field.convert([1, 2], @doc)
      @doc.verify
    end

    it "doesn't allow conversion from nil" do
      refute(@field.convert(nil, @doc))
    end
  end

  describe "StringConverter" do
    before do
      @field = self.class::Field.new(String)
    end

    it "allows conversion to UTF-8 string from binary" do
      refute(@field.convert("test", self))

      str = @field.convert("\xfe\xff\x00t\x00e\x00s\x00t".b, self)
      assert_equal('test', str)
      assert_equal(Encoding::UTF_8, str.encoding)
      str = @field.convert("Testing\x9c\x92".b, self)
      assert_equal("Testing\u0153\u2122", str)
      assert_equal(Encoding::UTF_8, str.encoding)
    end

    def config
      HexaPDF::Configuration.with_defaults
    end

    it "calls document.on_invalid_string if the provided string is invalid" do
      str = "\xfe\xff\xD8\x00\x00s\x00t".b
      assert_equal("st", @field.convert(str, self))
    end
  end

  describe "PDFByteStringConverter" do
    before do
      @field = self.class::Field.new(self.class::PDFByteString)
    end

    it "additionally adds String as allowed type if not already present" do
      assert_equal([HexaPDF::Dictionary::PDFByteString, String], @field.type)
    end

    it "allows conversion to a binary string" do
      refute(@field.convert('test'.b, self))

      input = "test"
      str = @field.convert(input, self)
      assert_equal('test', str)
      refute_same(input, str)
      assert_equal(Encoding::BINARY, str.encoding)
    end
  end

  describe "DateConverter" do
    before do
      @field = self.class::Field.new(self.class::PDFDate)
    end

    it "additionally adds String/Time/Date/DateTime as allowed types" do
      assert_equal([HexaPDF::Dictionary::PDFDate, String, Time, Date, DateTime], @field.type)
    end

    it "allows conversion to a Time object from a binary string" do
      refute(@field.convert('test'.b, self))

      [
        ["D:1998", [1998, 01, 01, 00, 00, 00, "-00:00"]],
        ["D:199812", [1998, 12, 01, 00, 00, 00, "-00:00"]],
        ["D:19981223", [1998, 12, 23, 00, 00, 00, "-00:00"]],
        ["D:1998122319", [1998, 12, 23, 19, 00, 00, "+00:00"]],
        ["D:199812231952", [1998, 12, 23, 19, 52, 00, "+00:00"]],
        ["D:19981223195210", [1998, 12, 23, 19, 52, 10, "+00:00"]],
        ["D:19981223195210-08'00'", [1998, 12, 23, 19, 52, 10, "-08:00"]],
        ["D:1998122319-08'00'", [1998, 12, 23, 19, 00, 00, "-08:00"]],
        ["D:19981223-08'00'", [1998, 12, 23, 00, 00, 00, "-08:00"]],
        ["D:199812-08'00'", [1998, 12, 01, 00, 00, 00, "-08:00"]],
        ["D:1998-08'00'", [1998, 01, 01, 00, 00, 00, "-08:00"]],
        ["D:19981223195210Z", [1998, 12, 23, 19, 52, 10, "+00:00"]],
        ["D:19981223195210Z00", [1998, 12, 23, 19, 52, 10, "+00:00"]],
        ["D:19981223195210Z00'00", [1998, 12, 23, 19, 52, 10, "+00:00"]],
        ["D:19981223195210-08", [1998, 12, 23, 19, 52, 10, "-08:00"]], # missing '
        ["D:19981223195210-08'00", [1998, 12, 23, 19, 52, 10, "-08:00"]], # no trailing ', as per PDF 2.0
        ["D:19981223195210-08'00''", [1998, 12, 23, 19, 52, 10, "-08:00"]], # two trailing '
        ["D:19981223195210-54'00", [1998, 12, 23, 19, 52, 10, "-23:59:59"]], #  TZ hour too large
        ["D:19981223195210+10'65", [1998, 12, 23, 19, 52, 10, "+11:05"]], # TZ min too large
        ["D:19982423195210-08'00'", [1998, 12, 23, 19, 52, 10, "-08:00"]], # months too large
        ["D:19981273195210-08'00'", [1998, 12, 31, 19, 52, 10, "-08:00"]], # day too large
        ["D:19981223275210-08'00'", [1998, 12, 23, 23, 52, 10, "-08:00"]], # hour too large
        ["D:19981223197710-08'00'", [1998, 12, 23, 19, 59, 10, "-08:00"]], # minute too large
        ["D:19981223195280-08'00'", [1998, 12, 23, 19, 52, 59, "-08:00"]], # seconds too large
      ].each do |str, data|
        obj = @field.convert(str, self)
        assert_equal(Time.new(*data), obj, "date str used: #{str}")
      end
    end
  end

  describe "FileSpecificationConverter" do
    before do
      @field = self.class::Field.new(:Filespec)
    end

    it "additionally adds Hash and String as allowed types" do
      assert(@field.type.include?(Hash))
      assert(@field.type.include?(String))
    end

    it "allows conversion from a string" do
      @doc = Minitest::Mock.new
      @doc.expect(:wrap, :data, [{F: 'test'}], type: HexaPDF::Type::FileSpecification)
      @field.convert('test', @doc)
      @doc.verify
    end

    it "allows conversion from a hash/dictionary" do
      @doc = Minitest::Mock.new
      @doc.expect(:wrap, :data, [{F: 'test'}], type: HexaPDF::Type::FileSpecification)
      @field.convert({F: 'test'}, @doc)
      @doc.verify
    end
  end

  describe "RectangleConverter" do
    before do
      @field = self.class::Field.new(HexaPDF::Rectangle)
    end

    it "additionally adds Array as allowed types" do
      assert_equal([HexaPDF::Rectangle, Array], @field.type)
    end

    it "allows conversion to a Rectangle from an Array" do
      doc = Minitest::Mock.new
      doc.expect(:wrap, :data, [[0, 1, 2, 3]], type: HexaPDF::Rectangle)
      @field.convert([0, 1, 2, 3], doc)
      doc.verify
    end

    it "allows conversion to a Rectangle from a HexaPDF::PDFArray" do
      data = HexaPDF::PDFArray.new([0, 1, 2, 3])
      doc = Minitest::Mock.new
      doc.expect(:wrap, :data, [data], type: HexaPDF::Rectangle)
      @field.convert(data, doc)
      doc.verify
    end

    it "converts to a null value if an (invalid) empty array is given" do
      doc = Minitest::Mock.new
      doc.expect(:wrap, :data, [nil])
      @field.convert([], doc)
      doc.verify
    end
  end

  describe "IntegerConverter" do
    before do
      @field = self.class::Field.new(Integer)
    end

    it "no additional field types allowed" do
      assert_equal([Integer], @field.type)
    end

    it "allows conversion to an Integer from an equivalent Float value" do
      refute_same(3, @field.convert(3.1, nil))
      assert_same(3, @field.convert(3.0, nil))
    end
  end
end
