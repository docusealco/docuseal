# frozen_string_literal: true

require 'spec_helper'
require 'rubyXL/convenience_methods/color'

describe RubyXL::RgbColor do
  describe '.to_s' do
    it 'should properly translate RGB color to string' do
      rgb_color = RubyXL::RgbColor.new

      rgb_color.r = 1
      rgb_color.g = 2
      rgb_color.b = 255

      expect(rgb_color.to_s).to eq('0102ff')
    end

    it 'should properly translate RGB color with alpha value to string' do
      rgb_color = RubyXL::RgbColor.new

      rgb_color.r = 11
      rgb_color.g = 22
      rgb_color.b = 33
      rgb_color.a = 255

      expect(rgb_color.to_s).to eq('0b1621ff')
    end
  end
end
