# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/document'
require 'hexapdf/task/dereference'

describe HexaPDF::Task::Dereference do
  before do
    @doc = HexaPDF::Document.new(io: StringIO.new(MINIMAL_PDF))
  end

  it "dereferences all references to objects" do
    obj = @doc.add(:test)
    len = @doc.add(5)
    str = @doc.add(@doc.wrap({Length: len}, stream: ''))
    @doc.trailer[:Test] = str
    pages = @doc.wrap({Type: :Pages})
    pages.add_page(@doc.wrap({Type: :Page}))
    @doc.trailer[:Test2] = pages
    @doc.trailer[:InvalidRef] = HexaPDF::Reference.new(5000, 2)

    checker = lambda do |val, done = {}|
      case val
      when Array then val.all? {|v| checker.call(v, done) }
      when Hash then val.all? {|_, v| checker.call(v, done) }
      when HexaPDF::Reference
        false
      when HexaPDF::Object
        if done.key?(val)
          true
        else
          done[val] = true
          checker.call(val.value, done)
        end
      else
        true
      end
    end
    refute(checker.call(@doc.trailer))
    assert_equal([obj, len], @doc.task(:dereference))
    assert(checker.call(@doc.trailer))
    assert_equal([obj, len], @doc.task(:dereference))
    assert(checker.call(@doc.trailer))
  end

  it "dereferences only a single object" do
    assert(@doc.object(5).value[:Font][:F1].kind_of?(HexaPDF::Reference))
    assert_nil(@doc.task(:dereference, object: @doc.object(5)))
    refute(@doc.object(5).value[:Font][:F1].kind_of?(HexaPDF::Reference))
  end
end
