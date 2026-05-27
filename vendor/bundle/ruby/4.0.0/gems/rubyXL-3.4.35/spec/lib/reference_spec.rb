# frozen_string_literal: true

require 'spec_helper'

describe RubyXL::Reference do
  describe '.ind2ref' do
    it "should correctly return the 'Excel Style' description of cells when given a row/column number" do
      expect(RubyXL::Reference.ind2ref(0, 26)).to eq('AA1')
      expect(RubyXL::Reference.ind2ref(99, 0)).to eq('A100')
      expect(RubyXL::Reference.ind2ref(0, 26)).to eq('AA1')
      expect(RubyXL::Reference.ind2ref(0, 51)).to eq('AZ1')
      expect(RubyXL::Reference.ind2ref(0, 52)).to eq('BA1')
      expect(RubyXL::Reference.ind2ref(0, 77)).to eq('BZ1')
      expect(RubyXL::Reference.ind2ref(0, 78)).to eq('CA1')
      expect(RubyXL::Reference.ind2ref(0, 16383)).to eq('XFD1')
    end

    it "should correctly convert back and forth between 'Excel Style' and index style cell references" do
      0.upto(16383) do |n|
        expect(RubyXL::Reference.ref2ind(RubyXL::Reference.ind2ref(n, 16383 - n))).to eq([ n, 16383 - n ])
      end
    end
  end

  describe '.valid?' do
    it 'should return true for valid references' do
      expect(RubyXL::Reference.new('C23').valid?).to be true
    end

    it 'should return false for invalid references' do
      expect(RubyXL::Reference.new('C2A').valid?).to be false
    end
  end

  describe '.ref2ind' do
    it 'should return [-1, -1] if the Excel index is not well-formed' do
      expect(RubyXL::Reference.ref2ind('A1B')).to eq([-1, -1])
    end
  end

  describe '.new' do
    it 'should take a string parameter' do
      new_ref = RubyXL::Reference.new('C23')
      expect(new_ref.single_cell?).to be true
      expect(new_ref.to_s).to eq 'C23'
    end

    it 'should take 2 coordinate parameters' do
      new_ref = RubyXL::Reference.new(11, 22)
      expect(new_ref.single_cell?).to be true
      expect(new_ref.to_s).to eq 'W12'
    end

    it 'should take 4 coordinate parameters' do
      new_ref = RubyXL::Reference.new(11, 22, 33, 44)
      expect(new_ref.single_cell?).to be false
      expect(new_ref.to_s).to eq 'AH12:AS23'
    end

    it 'should take named parameters' do
      expect(RubyXL::Reference.new(row_from: 44, row_to: 33, col_from: 22, col_to: 11).to_s).to eq('W45:L34')
    end
  end
end
