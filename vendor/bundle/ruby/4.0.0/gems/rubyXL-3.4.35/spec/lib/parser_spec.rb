# frozen_string_literal: true

require 'English'
require 'spec_helper'
require 'tmpdir'

describe RubyXL::Parser do
  before do
    @test_sheet_name = 'This is a very long sheet name that should be trimmed ' \
                       'to 31 characters for compatibility with MS Excel'
    @workbook = RubyXL::Workbook.new
    @workbook.add_worksheet('Test Worksheet')
    @time = Time.at(Time.now.to_i) # Excel only saves times with 1-second precision.
    @time2 = @time + 123456

    ws = @workbook.add_worksheet('Escape Test')
    ws.add_cell(0, 0, '&')
    ws.add_cell(0, 1, '<')
    ws.add_cell(0, 2, '>')
    ws.add_cell(0, 3, '')

    ws.add_cell(1, 0, '&') #TODO# .datatype = RubyXL::Cell::SHARED_STRING
    ws.add_cell(1, 1, '<') #TODO# .datatype = RubyXL::Cell::SHARED_STRING
    ws.add_cell(1, 2, '>') #TODO# .datatype = RubyXL::Cell::SHARED_STRING
    ws.add_cell(1, 3, '')

    ws.add_cell(2, 0, 0)
    ws.add_cell(2, 1, 12345)
    ws.add_cell(2, 2, 123.456e78)
    ws.add_cell(2, 3, 123.456e-78)

    ws.add_cell(3, 0, -0)
    ws.add_cell(3, 1, -12345)
    ws.add_cell(3, 2, -123.456e78)
    ws.add_cell(3, 3, -123.456e-78)

    ws[3][3].set_number_format('#.###')

    @workbook.add_worksheet(@test_sheet_name)

    @workbook.creator = 'test creator'
    @workbook.modifier = 'test modifier'
    @workbook.created_at = @time
    @workbook.modified_at = @time2

    @time_str = Time.now.to_s
    @file = "rubyXL-#{$PROCESS_ID}-#{DateTime.now.strftime('%Q')}.xlsx"
    @workbook.write(@file)
  end

  describe '.parse' do
    it 'should parse a valid Excel xlsx or xlsm workbook correctly' do
      @workbook2 = RubyXL::Parser.parse(@file)

      expect(@workbook2).to be_an_instance_of(::RubyXL::Workbook)

      expect(@workbook2.worksheets.size).to eq(@workbook.worksheets.size)
      @workbook2.worksheets.each_index { |i|
        expect(@workbook2[i]).to be_an_instance_of(::RubyXL::Worksheet)
      }
    end

    it 'should cause an error if an xlsx or xlsm workbook is not passed' do
      expect { @workbook2 = RubyXL::Parser.parse('nonexistent_file.tmp') }.to raise_error(Zip::Error)
    end

    it 'should construct consistent number formats' do
      @workbook2 = RubyXL::Parser.parse(@file)
      expect(@workbook2.stylesheet.number_formats).to be_instance_of(RubyXL::NumberFormats)
      expect(@workbook2.stylesheet.number_formats.size).to eq(1)
    end

    it 'should unescape HTML entities properly' do
      @workbook2 = RubyXL::Parser.parse(@file)
      expect(@workbook2['Escape Test'][0][0].value).to eq('&')
      expect(@workbook2['Escape Test'][0][1].value).to eq('<')
      expect(@workbook2['Escape Test'][0][2].value).to eq('>')

      expect(@workbook2['Escape Test'][1][0].value).to eq('&')
      expect(@workbook2['Escape Test'][1][1].value).to eq('<')
      expect(@workbook2['Escape Test'][1][2].value).to eq('>')
    end

    it 'should parse Core properties correctly' do
      @workbook2 = RubyXL::Parser.parse(@file)
      expect(@workbook2.creator).to eq('test creator')
      expect(@workbook2.modifier).to eq('test modifier')
      expect(@workbook2.created_at).to eq(@time)
      expect(@workbook2.modified_at).to eq(@time2)
    end

    it 'should trim excessively long sheet names on save' do
      @workbook2 = RubyXL::Parser.parse(@file)
      expect(@workbook2[@test_sheet_name]).to be_nil
      expect(@workbook2[@test_sheet_name[0..30]]).not_to be_nil
    end
  end

  describe 'parse_buffer' do
    it 'should parse string buffer correctly' do
      buffer = File.read(@file)
      expect(buffer).to be_instance_of(String)
      f = RubyXL::Parser.parse_buffer(buffer)
      expect(f).to be_instance_of(RubyXL::Workbook)
    end

    it 'should parse an IO object correctly' do
      io = File.open(@file)
      expect(io).to be_instance_of(File)
      f = RubyXL::Parser.parse_buffer(io)
      expect(f).to be_instance_of(RubyXL::Workbook)
    end
  end

  after do
    FileUtils.rm_f(@file)
  end
end
