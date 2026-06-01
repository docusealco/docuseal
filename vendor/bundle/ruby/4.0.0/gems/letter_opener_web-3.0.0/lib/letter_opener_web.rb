# frozen_string_literal: true

require 'letter_opener_web/version'
require 'letter_opener_web/engine'
require 'rexml/document'

module LetterOpenerWeb
  class Config
    attr_accessor :letters_location
  end

  def self.config
    @config ||= Config.new.tap do |conf|
      conf.letters_location = Rails.root.join('tmp', 'letter_opener')
    end
  end

  def self.configure
    yield config if block_given?
  end

  def self.reset!
    @config = nil
  end
end
