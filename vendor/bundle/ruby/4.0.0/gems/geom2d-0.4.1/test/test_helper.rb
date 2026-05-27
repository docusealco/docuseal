# -*- frozen_string_literal: true -*-

begin
  require 'simplecov'
  SimpleCov.start { add_filter '/test/' }
rescue LoadError
  warn "Gem 'simplecov' not installed, not generating coverage report"
end

require 'minitest/autorun'

module TestHelper
end

Minitest::Spec.send(:include, TestHelper)
