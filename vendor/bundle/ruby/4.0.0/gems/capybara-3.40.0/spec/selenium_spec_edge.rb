# frozen_string_literal: true

require 'spec_helper'
require 'selenium-webdriver'
require 'shared_selenium_session'
require 'shared_selenium_node'
require 'rspec/shared_spec_matchers'

# unless ENV['CI']
#   Selenium::WebDriver::Edge::Service.driver_path = '/usr/local/bin/msedgedriver'
# end

Selenium::WebDriver.logger.ignore(:selenium_manager)

if Selenium::WebDriver::Platform.mac?
  Selenium::WebDriver::Edge.path = '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'
end

Capybara.register_driver :selenium_edge do |app|
  # ::Selenium::WebDriver.logger.level = "debug"
  # If we don't create an options object the path set above won't be used

  # browser_options = Selenium::WebDriver::Edge::Options.new
  # browser_options.add_argument('--headless') if ENV['HEADLESS']

  browser_options = if ENV['HEADLESS']
    Selenium::WebDriver::Options.edge(args: ['--headless=new'])
  else
    Selenium::WebDriver::Options.edge
  end

  Capybara::Selenium::Driver.new(app, browser: :edge, options: browser_options).tap do |driver|
    driver.browser
    driver.download_path = Capybara.save_path
  end
end

module TestSessions
  SeleniumEdge = Capybara::Session.new(:selenium_edge, TestApp)
end

skipped_tests = %i[response_headers status_code trigger]

Capybara::SpecHelper.log_selenium_driver_version(Selenium::WebDriver::Edge) if ENV['CI']

Capybara::SpecHelper.run_specs TestSessions::SeleniumEdge, 'selenium', capybara_skip: skipped_tests do |example|
  case example.metadata[:full_description]
  when 'Capybara::Session selenium #attach_file with a block can upload by clicking the file input'
    pending "Edge doesn't allow clicking on file inputs"
  when /Capybara::Session selenium node #shadow_root should get visible text/
    pending "Selenium doesn't currently support getting visible text for shadow root elements"
  end
end

RSpec.describe 'Capybara::Session with Edge', capybara_skip: skipped_tests do
  include Capybara::SpecHelper
  ['Capybara::Session', 'Capybara::Node', Capybara::RSpecMatchers].each do |examples|
    include_examples examples, TestSessions::SeleniumEdge, :selenium_edge
  end
end
