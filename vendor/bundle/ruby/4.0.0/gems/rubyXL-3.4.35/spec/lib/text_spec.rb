# frozen_string_literal: true

require 'spec_helper'

describe RubyXL::Text do
  describe '.to_s' do
    it 'should not crash processing UNICODE data' do
      bytes = [ 114, 39, 95, 120, 48, 48, 56, 48, 95, 226, 132, 162, 115,
                32, 103, 105, 114, 108, 102, 114, 105, 101, 110, 100,
                39, 95, 120, 48, 48, 56, 48, 95, 226, 132, 162, 115, 32, 104, 111]

      t = RubyXL::Text.new(:value => bytes.pack('c*').force_encoding('UTF-8'))

      str = t.to_s

      expect(str).to be
    end

    it 'should not escape valid XML extended UNICODE characters' do
      t = RubyXL::Text.new(:value => "\u{10000}\u{10FFFF}")

      xml = t.write_xml[%r{<t>[^<]+</t>}]

      expect(xml).to eq("<t>\u{10000}\u{10FFFF}</t>")
    end
  end
end
