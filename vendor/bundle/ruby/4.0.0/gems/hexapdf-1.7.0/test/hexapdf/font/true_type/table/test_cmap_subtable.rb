# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'hexapdf/font/true_type/table/cmap_subtable'

describe HexaPDF::Font::TrueType::Table::CmapSubtable do
  before do
    @klass = HexaPDF::Font::TrueType::Table::CmapSubtable
  end

  describe "initialize" do
    it "uses default values" do
      t = @klass.new(3, 1)
      assert_equal(3, t.platform_id)
      assert_equal(1, t.encoding_id)
      assert_nil(t.format)
      assert_equal(0, t.language)
    end
  end

  describe "unicode?" do
    it "identifies (0,x), (3,1) and (3,10) as unicode" do
      assert(@klass.new(0, 1).unicode?)
      assert(@klass.new(0, 5).unicode?)
      assert(@klass.new(3, 1).unicode?)
      assert(@klass.new(3, 10).unicode?)
      refute(@klass.new(1, 0).unicode?)
      refute(@klass.new(3, 0).unicode?)
    end
  end

  describe "inspect" do
    it "can represent itself nicely" do
      assert_equal("#<#{@klass.name} (3, 1, 0, nil)>", @klass.new(3, 1).inspect)
    end
  end

  describe "parse" do
    def table(data)
      @klass.new(3, 1).tap {|obj| obj.parse(StringIO.new(data), 0) }
    end

    it "works for format 0" do
      t = table([0, 262, 0].pack('n3') + [255].pack('C*') + (0..254).to_a.pack('C*'))
      assert_equal(0, t.gid_to_code(255))
      assert_equal(234, t.gid_to_code(233))

      assert_equal(255, t[0])
      assert_equal(233, t[234])
      assert_nil(t[256])

      assert_raises(HexaPDF::Error) { table([0, 20, 0].pack('n3') + "a" * 20)[0] }
    end

    it "works for format 2" do
      f2 = ([0, 8] + [0] * 254).pack('n*') +
        [[0, 256, 0, 2 + 8], [0x33, 3, 5, 2 + 256 * 2]].map {|a| a.pack('n2s>n') }.join +
        ((0..255).to_a + [35, 65534, 0]).pack('n*')
      t = table([2, f2.length + 6, 0].pack('n3') << f2)
      assert_nil(t[0x0132])
      assert_equal(40, t[0x0133])
      assert_equal(3, t[0x0134])
      assert_nil(t[0x0135])
      assert_nil(t[0x0136])
      assert_equal(16, t[0x1036])
      assert_nil(t[0xfffff])

      assert_equal(0x0133, t.gid_to_code(40))
      assert_equal(0x0134, t.gid_to_code(3))
      assert_equal(16, t.gid_to_code(16))
    end

    it "works for format 4" do
      f4 = [6, 8, 2, 4,  35, 134, 65535, 0, 30, 133, 65535, 100, 110, 120,
            0, 6, 2, 65500, 0, 1].pack('n*')
      t = table([4, f4.length + 6, 0].pack('n3') << f4)
      assert_nil(t[25])
      assert_equal(130, t[30])
      assert_equal(133, t[33])
      assert_equal(135, t[35])
      assert_nil(t[36])
      assert_nil(t[133])
      assert_equal(111, t[134])
      assert_equal(84, t[65535])
      assert_nil(t[70000])

      assert_equal(30, t.gid_to_code(130))
      assert_equal(33, t.gid_to_code(133))
      assert_equal(35, t.gid_to_code(135))
      assert_equal(134, t.gid_to_code(111))
      assert_equal(65535, t.gid_to_code(84))
    end

    it "works for format 4 with invalid 0xffff entry" do
      f4 = [2, 0, 0, 0, 65535, 0, 65535, 0, 32767].pack('n*')
      t = table([4, f4.length + 6, 0].pack('n3') << f4)
      assert_nil(t[65535])
      assert_equal(65535, t.gid_to_code(0))
    end

    it "works for format 6" do
      t = table(([6, 30, 0, 1024, 10] + (1..10).to_a).pack('n*'))
      assert_nil(t[0])
      assert_equal(1, t[1024])
      assert_equal(7, t[1030])
      assert_equal(10, t[1033])
      assert_nil(t[1034])

      assert_equal(1033, t.gid_to_code(10))
    end

    it "works for format 10" do
      t = table([10, 0].pack('n2') + [40, 0, 1024, 10].pack('N*') + (1..10).to_a.pack('n*'))
      assert_nil(t[234])
      assert_equal(1, t[1024])
      assert_equal(7, t[1030])
      assert_equal(10, t[1033])
      assert_nil(t[1034])

      assert_equal(1033, t.gid_to_code(10))
    end

    it "works for format 12" do
      t = table([12, 0].pack('n2') + [40, 0, 2, 35, 38, 1000, 70000, 90000, 80000].pack('N*'))
      assert_nil(t[30])
      assert_equal(1000, t[35])
      assert_equal(1003, t[38])
      assert_equal(100_000, t[90_000])
      assert_nil(t[90_001])

      assert_equal(35, t.gid_to_code(1000))
      assert_equal(38, t.gid_to_code(1003))
      assert_equal(90_000, t.gid_to_code(100_000))
    end

    it "returns false if a format is not supported" do
      refute(@klass.new(3, 1).parse(StringIO.new("\x00\x03".b), 0))
    end
  end
end
