# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/type/optional_content_configuration'
require 'hexapdf/document'

describe HexaPDF::Type::OptionalContentConfiguration do
  before do
    @doc = HexaPDF::Document.new
    @oc_config = @doc.optional_content.default_configuration
    @ocg = @doc.optional_content.ocg('Test')
  end

  describe "ocg_state" do
    it "defaults to the base state if nothing specific is set" do
      assert_equal(:on, @oc_config.ocg_state(@ocg))
      @oc_config[:BaseState] = :OFF
      assert_equal(:off, @oc_config.ocg_state(@ocg))
      @oc_config[:BaseState] = :Unchanged
      assert_nil(@oc_config.ocg_state(@ocg))
    end

    it "returns :on if the OCG is in the /ON key" do
      @oc_config[:ON] = [@ocg]
      [:ON, :OFF, :Unchanged].each do |base_state|
        @oc_config[:BaseState] = base_state
        assert_equal(:on, @oc_config.ocg_state(@ocg))
      end
    end

    it "returns :off if the OCG is in the /OFF key" do
      @oc_config[:OFF] = [@ocg]
      [:ON, :OFF, :Unchanged].each do |base_state|
        @oc_config[:BaseState] = base_state
        assert_equal(:off, @oc_config.ocg_state(@ocg))
      end
    end

    it "adds the OCG to the respective dictionary key if a state is given" do
      [[:ON, :OFF], [:OFF, :ON]].each do |state, other_state|
        @oc_config[other_state] = [@ocg]
        @oc_config.ocg_state(@ocg, state.downcase)
        assert_equal([], @oc_config[other_state].value)
        assert_equal([@ocg], @oc_config[state].value)
        @oc_config.ocg_state(@ocg, state)
        assert_equal([@ocg], @oc_config[state].value)
      end
    end

    it "fails if an invalid state is given" do
      assert_raises(ArgumentError) { @oc_config.ocg_state(@ocg, :unknwo) }
    end
  end

  it "returns whether a given ocg is on" do
    assert(@oc_config.ocg_on?(@ocg))
    @oc_config[:OFF] = [@ocg]
    refute(@oc_config.ocg_on?(@ocg))
  end

  describe "add_ocg_to_ui" do
    it "adds the ocg to the top level" do
      @oc_config.add_ocg_to_ui(@ocg)
      @oc_config.add_ocg_to_ui(@ocg)
      assert_equal([@ocg, @ocg], @oc_config[:Order].value)
    end

    it "adds the ocg under an existing label" do
      @oc_config[:Order] = [:ocg1, ['Test'], :ocg2]
      @oc_config.add_ocg_to_ui(@ocg, path: 'Test')
      @oc_config.add_ocg_to_ui(@ocg, path: 'Test')
      assert_equal([:ocg1, ['Test', @ocg, @ocg], :ocg2], @oc_config[:Order].value)
    end

    it "adds the ocg under a new label" do
      @oc_config[:Order] = []
      @oc_config.add_ocg_to_ui(@ocg, path: 'Test')
      @oc_config.add_ocg_to_ui(@ocg, path: 'Test')
      @oc_config.add_ocg_to_ui(@ocg, path: 'Test2')
      assert_equal([['Test', @ocg, @ocg], ['Test2', @ocg]], @oc_config[:Order].value)
    end

    it "adds the ocg under an existing ocg" do
      @oc_config[:Order] = [:ocg1, :ocg2]
      @oc_config.add_ocg_to_ui(@ocg, path: :ocg2)
      @oc_config.add_ocg_to_ui(@ocg, path: :ocg2)
      assert_equal([:ocg1, :ocg2, [@ocg, @ocg]], @oc_config[:Order].value)
    end

    it "adds the ocg under a new ocg" do
      @oc_config[:Order] = []
      @oc_config.add_ocg_to_ui(@ocg, path: :ocg1)
      @oc_config.add_ocg_to_ui(@ocg, path: :ocg1)
      @oc_config.add_ocg_to_ui(@ocg, path: :ocg2)
      assert_equal([:ocg1, [@ocg, @ocg], :ocg2, [@ocg]], @oc_config[:Order].value)
    end

    it "adds the ocg under an existing multi-level path" do
      @oc_config[:Order] = [:ocg1, ['Test', :ocg2, [:ocg4, ['Test2', :ocg5]]], :ocg3]
      @oc_config.add_ocg_to_ui(@ocg, path: ['Test', :ocg2, 'Test2'])
      assert_equal([:ocg1, ['Test', :ocg2, [:ocg4, ['Test2', :ocg5, @ocg]]], :ocg3],
                   @oc_config[:Order].value)
    end

    it "adds the ocg under a new multi-level path" do
      @oc_config[:Order] = [:ocg1, ['Test', :ocg2]]
      @oc_config.add_ocg_to_ui(@ocg, path: ['Test2', :ocg3, 'Test3'])
      assert_equal([:ocg1, ['Test', :ocg2], ['Test2', :ocg3, [['Test3', @ocg]]]],
                   @oc_config[:Order].value)
    end
  end
end
