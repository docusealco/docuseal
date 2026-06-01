# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LetterOpenerWeb do
  subject { described_class }
  after(:each) { described_class.reset! }

  describe '.config' do
    it 'sets defaults' do
      expected = Rails.root.join('tmp', 'letter_opener')
      expect(subject.config.letters_location).to eq(expected)
    end
  end

  describe '.configure' do
    it 'yields config to the block' do
      subject.configure do |config|
        expect(config).to eq(subject.config)
      end
    end

    it 'retains settings set within the block' do
      subject.configure do |config|
        config.letters_location = 'tmp/test_path'
      end

      expect(subject.config.letters_location).to eq('tmp/test_path')
    end
  end

  describe '.reset!' do
    it 'resets configuration' do
      subject.configure do |config|
        config.letters_location = 'tmp/test_path'
      end

      subject.reset!

      expected = Rails.root.join('tmp', 'letter_opener')
      expect(subject.config.letters_location).to eq(expected)
    end
  end
end
