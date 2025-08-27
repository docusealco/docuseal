# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AtsPrefill::CacheManager do
  describe '.generate_cache_key' do
    it 'generates a consistent cache key with SHA256 hash' do
      key1 = described_class.generate_cache_key('test', 'data')
      key2 = described_class.generate_cache_key('test', 'data')

      expect(key1).to eq(key2)
      expect(key1).to match(/\Atest:[a-f0-9]{64}\z/)
    end

    it 'generates different keys for different data' do
      key1 = described_class.generate_cache_key('test', 'data1')
      key2 = described_class.generate_cache_key('test', 'data2')

      expect(key1).not_to eq(key2)
    end

    it 'generates different keys for different prefixes' do
      key1 = described_class.generate_cache_key('prefix1', 'data')
      key2 = described_class.generate_cache_key('prefix2', 'data')

      expect(key1).not_to eq(key2)
    end
  end

  describe '.fetch_field_extraction' do
    let(:cache_key) { 'test_key' }
    let(:expected_value) { %w[field1 field2] }

    it 'returns cached value when available' do
      allow(Rails.cache).to receive(:fetch)
        .with(cache_key, expires_in: described_class::FIELD_EXTRACTION_TTL)
        .and_return(expected_value)

      result = described_class.fetch_field_extraction(cache_key) { 'should not be called' }

      expect(result).to eq(expected_value)
    end

    it 'computes and caches value when not cached' do
      allow(Rails.cache).to receive(:fetch).with(cache_key, expires_in: described_class::FIELD_EXTRACTION_TTL).and_yield

      result = described_class.fetch_field_extraction(cache_key) { expected_value }

      expect(result).to eq(expected_value)
    end

    it 'falls back to computation when cache fails' do
      allow(Rails.cache).to receive(:fetch).and_raise(StandardError, 'Cache error')

      result = described_class.fetch_field_extraction(cache_key) { expected_value }

      expect(result).to eq(expected_value)
    end
  end

  describe '.fetch_field_mapping' do
    let(:cache_key) { 'test_key' }
    let(:expected_value) { { 'field1' => 'uuid1' } }

    it 'returns cached value when available' do
      allow(Rails.cache).to receive(:fetch)
        .with(cache_key, expires_in: described_class::FIELD_MAPPING_TTL)
        .and_return(expected_value)

      result = described_class.fetch_field_mapping(cache_key) { 'should not be called' }

      expect(result).to eq(expected_value)
    end

    it 'computes and caches value when not cached' do
      allow(Rails.cache).to receive(:fetch).with(cache_key, expires_in: described_class::FIELD_MAPPING_TTL).and_yield

      result = described_class.fetch_field_mapping(cache_key) { expected_value }

      expect(result).to eq(expected_value)
    end

    it 'falls back to computation when cache fails' do
      allow(Rails.cache).to receive(:fetch).and_raise(StandardError, 'Cache error')

      result = described_class.fetch_field_mapping(cache_key) { expected_value }

      expect(result).to eq(expected_value)
    end
  end

  describe '.write_to_cache' do
    let(:cache_key) { 'test_key' }
    let(:value) { 'test_value' }
    let(:ttl) { 3600 }

    it 'writes to cache successfully' do
      allow(Rails.cache).to receive(:write)

      described_class.write_to_cache(cache_key, value, ttl)

      expect(Rails.cache).to have_received(:write).with(cache_key, value, expires_in: ttl)
    end

    it 'handles cache write errors gracefully' do
      allow(Rails.cache).to receive(:write).and_raise(StandardError, 'Cache error')

      expect { described_class.write_to_cache(cache_key, value, ttl) }.not_to raise_error
    end
  end

  describe '.read_from_cache' do
    let(:cache_key) { 'test_key' }
    let(:cached_value) { 'cached_value' }

    it 'reads from cache successfully' do
      allow(Rails.cache).to receive(:read).with(cache_key).and_return(cached_value)

      result = described_class.read_from_cache(cache_key)

      expect(result).to eq(cached_value)
    end

    it 'returns nil when cache read fails' do
      allow(Rails.cache).to receive(:read).and_raise(StandardError, 'Cache error')

      result = described_class.read_from_cache(cache_key)

      expect(result).to be_nil
    end

    it 'returns nil when key not found' do
      allow(Rails.cache).to receive(:read).with(cache_key).and_return(nil)

      result = described_class.read_from_cache(cache_key)

      expect(result).to be_nil
    end
  end

  describe 'constants' do
    it 'defines expected TTL constants' do
      expect(described_class::FIELD_EXTRACTION_TTL).to eq(3600)
      expect(described_class::FIELD_MAPPING_TTL).to eq(1800)
      expect(described_class::MAX_CACHE_ENTRIES).to eq(1000)
    end
  end
end
