# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara::Server::Middleware::Counter do
  let(:counter) { described_class.new }
  let(:uri) { '/example' }

  describe '#increment' do
    it 'successfully' do
      counter.increment(uri)
      expect(counter).to be_positive
    end
  end

  describe '#decrement' do
    before do
      counter.increment(uri)
    end

    context 'successfully' do
      it 'with same uri' do
        expect(counter).to be_positive
        counter.decrement(uri)
        expect(counter).not_to be_positive
      end

      it 'with changed uri' do
        expect(counter).to be_positive
        counter.decrement('/')
        expect(counter).not_to be_positive
      end
    end
  end
end
