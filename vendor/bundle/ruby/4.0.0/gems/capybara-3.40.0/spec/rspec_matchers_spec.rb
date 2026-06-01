# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Capybara RSpec Matchers', type: :feature do
  context 'after called on session' do
    it 'HaveSelector should allow getting a description of the matcher' do
      visit('/with_html')
      matcher = have_selector(:css, 'h2.head', minimum: 3)
      expect(page).to matcher
      expect { matcher.description }.not_to raise_error
    end

    it 'HaveText should allow getting a description' do
      visit('/with_html')
      matcher = have_text('Lorem')
      expect(page).to matcher
      expect { matcher.description }.not_to raise_error
    end

    it 'should produce the same error for .to have_no_xxx and .not_to have_xxx' do
      visit('/with_html')
      not_to_msg = error_msg_for { expect(page).not_to have_selector(:css, '#referrer') }
      have_no_msg = error_msg_for { expect(page).to have_no_selector(:css, '#referrer') }
      expect(not_to_msg).to eq have_no_msg

      not_to_msg = error_msg_for { expect(page).not_to have_text('This is a test') }
      have_no_msg = error_msg_for { expect(page).to have_no_text('This is a test') }
      expect(not_to_msg).to eq have_no_msg
    end
  end

  context 'after called on element' do
    it 'HaveSelector should allow getting a description' do
      visit('/with_html')
      el = find(:css, '#first')
      matcher = have_selector(:css, 'a#foo')
      expect(el).to matcher
      expect { matcher.description }.not_to raise_error
    end

    it 'MatchSelector should allow getting a description' do
      visit('/with_html')
      el = find(:css, '#first')
      matcher = match_selector(:css, '#first')
      expect(el).to matcher
      expect { matcher.description }.not_to raise_error
    end

    it 'HaveText should allow getting a description' do
      visit('/with_html')
      el = find(:css, '#first')
      matcher = have_text('Lorem')
      expect(el).to matcher
      expect { matcher.description }.not_to raise_error
    end
  end

  context 'with a filter block' do
    it 'applies the filter' do
      visit('/with_html')
      expect(page).to have_selector(:css, 'input#test_field')

      expect(page).to have_selector(:css, 'input', count: 1) { |input| input.value == 'monkey' }
      expect(page).to have_selector(:css, 'input', count: 1) do |input|
        input.value == 'monkey'
      end
      expect(page).to have_no_selector(:css, 'input#test_field') { |input| input.value == 'not a monkey' }
      expect(page).to have_no_selector(:css, 'input#test_field') do |input|
        input.value == 'not a monkey'
      end

      expect(page).not_to have_selector(:css, 'input#test_field') { |input| input.value == 'not a monkey' }
      expect(page).not_to have_selector(:css, 'input#test_field') do |input|
        input.value == 'not a monkey'
      end
      expect(page).not_to have_no_selector(:css, 'input', count: 1) { |input| input.value == 'monkey' }
      expect(page).not_to have_no_selector(:css, 'input#test_field', count: 1) do |input|
        input.value == 'monkey'
      end
    end
  end

  def error_msg_for(&block)
    expect(&block).to(raise_error { |e| return e.message })
  end
end
