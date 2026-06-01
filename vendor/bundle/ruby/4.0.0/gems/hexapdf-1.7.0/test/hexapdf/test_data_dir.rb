# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/data_dir'

describe 'HexaPDF.data_dir' do
  before do
    @local = File.expand_path(File.join(__dir__, '..', '..', 'data', 'hexapdf'))
    @global = File.expand_path(File.join(RbConfig::CONFIG["datadir"], "hexapdf"))
    HexaPDF.remove_instance_variable(:@data_dir) if HexaPDF.instance_variable_defined?(:@data_dir)
  end

  after do
    HexaPDF.remove_instance_variable(:@data_dir) if HexaPDF.instance_variable_defined?(:@data_dir)
  end

  it "returns the 'local' data directory by default, e.g. in case of gem installations" do
    assert_equal(@local, HexaPDF.data_dir)
  end

  it "returns the global data directory if the local one isn't found" do
    File.stub(:directory?, lambda {|path| path != @local }) do
      assert_equal(@global, HexaPDF.data_dir)
    end
  end

  it "fails if no data directory is found" do
    File.stub(:directory?, lambda {|_path| false }) do
      assert_raises { HexaPDF.data_dir }
    end
  end
end
