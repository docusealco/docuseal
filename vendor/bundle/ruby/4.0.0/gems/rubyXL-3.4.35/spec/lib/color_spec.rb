# frozen_string_literal: true

require 'spec_helper'
require 'rubyXL/convenience_methods/color'

describe RubyXL::Color do
  describe '.validate_color' do
    it 'should return true if a valid hex color without a # is passed' do
      expect(RubyXL::Color.validate_color('0fbCAd')).to eq(true)
    end

    it 'should return true if a valid hex color with alpha is passed' do
      expect(RubyXL::Color.validate_color('01AbCdeF')).to eq(true)
    end

    it 'should cause an error if an invalid hex color code or one with a # is passed' do
      expect { RubyXL::Color.validate_color('#G') }.to raise_error(RuntimeError)
      expect { RubyXL::Color.validate_color('1234567') }.to raise_error(RuntimeError)
    end
  end
end
