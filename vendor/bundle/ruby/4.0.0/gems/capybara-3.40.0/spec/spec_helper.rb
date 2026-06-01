# frozen_string_literal: true

require 'rspec/expectations'
require 'webdrivers' if ENV.fetch('WEBDRIVERS', nil)
require 'selenium_statistics'
if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear! do
    add_filter '/lib/capybara/driver/'
    add_filter '/lib/capybara/registrations/'
  end
end
require 'capybara/spec/spec_helper'

module Capybara
  module SpecHelper
    def firefox?(session)
      browser_name(session) == :firefox &&
        ((defined?(::Selenium::WebDriver::VERSION) && (Gem::Version.new(::Selenium::WebDriver::VERSION) >= Gem::Version.new('4'))) ||
         session.driver.browser.capabilities.is_a?(::Selenium::WebDriver::Remote::W3C::Capabilities))
    end

    def firefox_lt?(version, session)
      firefox?(session) && (session.driver.browser.capabilities[:browser_version].to_f < version)
    end

    def firefox_gte?(version, session)
      firefox?(session) && (session.driver.browser.capabilities[:browser_version].to_f >= version)
    end

    def geckodriver_version(session)
      Gem::Version.new(session.driver.browser.capabilities['moz:geckodriverVersion'])
    end

    def geckodriver_gte?(version, session)
      firefox?(session) && geckodriver_version(session) >= Gem::Version.new(version)
    end

    def geckodriver_lt?(version, session)
      firefox?(session) && geckodriver_version(session) < Gem::Version.new(version)
    end

    def chrome?(session)
      browser_name(session) == :chrome
    end

    def chrome_version(session)
      (session.driver.browser.capabilities[:browser_version] ||
        session.driver.browser.capabilities[:version]).to_f
    end

    def chrome_lt?(version, session)
      chrome?(session) && (chrome_version(session) < version)
    end

    def chrome_gte?(version, session)
      chrome?(session) && (chrome_version(session) >= version)
    end

    def chromedriver_version(session)
      Gem::Version.new(session.driver.browser.capabilities['chrome']['chromedriverVersion'].split[0])
    end

    def chromedriver_gte?(version, session)
      chrome?(session) && chromedriver_version(session) >= Gem::Version.new(version)
    end

    def chromedriver_lt?(version, session)
      chrome?(session) && chromedriver_version(session) < Gem::Version.new(version)
    end

    def selenium?(session)
      session.driver.is_a? Capybara::Selenium::Driver
    end

    def selenium_lt?(version, session)
      selenium?(session) &&
        Gem::Version.new(::Selenium::WebDriver::VERSION) < Gem::Version.new(version)
    end

    def edge?(session)
      browser_name(session).to_s.start_with?('edge')
    end

    def legacy_edge?(session)
      browser_name(session) == :edge
    end

    def edge_lt?(version, session)
      edge?(session) && (chrome_version(session) < version)
    end

    def edge_gte?(version, session)
      edge?(session) && (chrome_version(session) >= version)
    end

    def ie?(session)
      %i[internet_explorer ie].include?(browser_name(session))
    end

    def safari?(session)
      %i[safari Safari Safari_Technology_Preview].include?(browser_name(session))
    end

    def browser_name(session)
      session.driver.browser.browser if session.respond_to?(:driver)
    end

    def remote?(session)
      session.driver.browser.is_a? ::Selenium::WebDriver::Remote::Driver
    end

    def self.log_selenium_driver_version(mod)
      mod = mod::Service if ::Selenium::WebDriver::Service.respond_to? :driver_path
      path = mod.driver_path
      path = path.call if path.respond_to? :call
      $stdout.puts `#{path.gsub(' ', '\ ')} --version` if path
    end
  end
end

RSpec.configure do |config|
  Capybara::SpecHelper.configure(config)
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.filter_run_including focus_: true unless ENV['CI']
  config.run_all_when_everything_filtered = true
  config.after(:suite) { SeleniumStatistics.print_results }
end
