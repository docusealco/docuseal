# frozen_string_literal: true

ENV["FERRUM_DEBUG"] = "true" if ENV["CUPRITE_DEBUG"]

require "ferrum"
require "capybara"
require "capybara/cuprite/driver"
require "capybara/cuprite/browser"
require "capybara/cuprite/page"
require "capybara/cuprite/options"
require "capybara/cuprite/node"
require "capybara/cuprite/errors"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app)
end
