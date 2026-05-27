# -*- encoding: utf-8 -*-

begin
  require 'simplecov'
  SimpleCov.start do
    minimum_coverage line: 100 unless ENV['NO_SIMPLECOV']
    add_filter '/test/'
    add_filter '/fast_arc4.rb'
  end
rescue LoadError
end

gem 'minitest'
begin
  gem 'minitest-mock'
  require 'minitest/mock'
rescue Gem::MissingSpecError
  # Assume Minitest < 6 is in use for older Rubies
end
gem 'strscan'
require 'minitest/autorun'
require 'fiber'
require 'zlib'
require 'hexapdf/test_utils'

TEST_DATA_DIR = File.join(__dir__, 'data')
MINIMAL_PDF = File.binread(File.join(TEST_DATA_DIR, 'minimal.pdf')).freeze

Minitest::Test.make_my_diffs_pretty!

ENV['TZ'] = 'UTC'
