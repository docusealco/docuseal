# frozen_string_literal: true

require "minitest/autorun"
require "rails-html-sanitizer"

puts "nokogiri version info: #{Nokogiri::VERSION_INFO}"
puts "html5 support: #{Rails::HTML::Sanitizer.html5_support?}"
