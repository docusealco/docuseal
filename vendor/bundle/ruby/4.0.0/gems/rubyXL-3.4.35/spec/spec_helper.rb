# frozen_string_literal: true

require 'rubygems'

require 'simplecov'
SimpleCov.start

require 'rubyXL'

RSpec.configure do |c|
  c.color = true
  c.formatter = :progress
end
