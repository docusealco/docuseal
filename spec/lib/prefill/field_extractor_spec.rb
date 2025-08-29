# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Prefill::FieldExtractor do
  describe '.call' do
    context 'when prefill_fields parameter is present' do
      let(:fields) { %w[employee_first_name employee_last_name employee_email] }
      let(:encoded_fields) { Base64.urlsafe_encode64(fields.to_json) }
      let(:params) { ActionController::Parameters.new(prefill_fields: encoded_fields) }

      it 'decodes and returns the ATS fields' do
        result = described_class.call(params)
        expect(result).to eq(fields)
      end

      it 'caches the result' do
        cache_key = Prefill::CacheManager.generate_cache_key('prefill_fields', encoded_fields)

        allow(Prefill::CacheManager).to receive(:fetch_field_extraction).and_call_original

        described_class.call(params)

        expect(Prefill::CacheManager).to have_received(:fetch_field_extraction).with(cache_key)
      end

      it 'returns cached result on subsequent calls' do
        cache_key = Prefill::CacheManager.generate_cache_key('prefill_fields', encoded_fields)
        cached_result = ['cached_field']

        allow(Prefill::CacheManager).to receive(:fetch_field_extraction).with(cache_key).and_return(cached_result)

        result = described_class.call(params)
        expect(result).to eq(cached_result)
      end
    end

    context 'when prefill_fields parameter is missing' do
      let(:params) { ActionController::Parameters.new({}) }

      it 'returns an empty array' do
        result = described_class.call(params)
        expect(result).to eq([])
      end
    end

    context 'when prefill_fields parameter is blank' do
      let(:params) { ActionController::Parameters.new(prefill_fields: '') }

      it 'returns an empty array' do
        result = described_class.call(params)
        expect(result).to eq([])
      end
    end

    context 'when prefill_fields parameter is invalid' do
      let(:params) { ActionController::Parameters.new(prefill_fields: 'invalid-base64') }

      it 'returns an empty array' do
        result = described_class.call(params)
        expect(result).to eq([])
      end
    end

    context 'when decoded JSON is not an array' do
      let(:invalid_data) { { not: 'an array' } }
      let(:encoded_invalid) { Base64.urlsafe_encode64(invalid_data.to_json) }
      let(:params) { ActionController::Parameters.new(prefill_fields: encoded_invalid) }

      it 'returns an empty array' do
        result = described_class.call(params)
        expect(result).to eq([])
      end
    end

    context 'when array contains non-string values' do
      let(:mixed_data) { ['employee_first_name', 123, 'employee_email'] }
      let(:encoded_mixed) { Base64.urlsafe_encode64(mixed_data.to_json) }
      let(:params) { ActionController::Parameters.new(prefill_fields: encoded_mixed) }

      it 'returns an empty array' do
        result = described_class.call(params)
        expect(result).to eq([])
      end
    end

    context 'when validating field names' do
      it 'accepts all valid field name patterns' do
        valid_fields = %w[
          employee_first_name
          employee_middle_name
          employee_last_name
          employee_email
          manager_firstname
          manager_lastname
          account_name
          location_name
          location_street
        ]
        encoded = Base64.urlsafe_encode64(valid_fields.to_json)
        params = ActionController::Parameters.new(prefill_fields: encoded)

        result = described_class.call(params)
        expect(result).to eq(valid_fields)
      end

      it 'rejects invalid field name patterns' do
        invalid_fields = %w[
          invalid_field
          employee
          _employee_name
          employee_name_
          EMPLOYEE_NAME
          employee-name
          employee.name
          malicious_script
          admin_password
        ]
        encoded = Base64.urlsafe_encode64(invalid_fields.to_json)
        params = ActionController::Parameters.new(prefill_fields: encoded)

        result = described_class.call(params)
        expect(result).to eq([])
      end

      it 'filters out invalid fields while keeping valid ones' do
        mixed_fields = %w[
          employee_first_name
          invalid_field
          manager_lastname
          malicious_script
          location_name
        ]
        expected_valid = %w[employee_first_name manager_lastname location_name]
        encoded = Base64.urlsafe_encode64(mixed_fields.to_json)
        params = ActionController::Parameters.new(prefill_fields: encoded)

        result = described_class.call(params)
        expect(result).to eq(expected_valid)
      end
    end

    context 'when handling errors' do
      it 'handles JSON parsing errors gracefully' do
        invalid_json = Base64.urlsafe_encode64('invalid json')
        params = ActionController::Parameters.new(prefill_fields: invalid_json)

        result = described_class.call(params)
        expect(result).to eq([])
      end

      it 'handles Base64 decoding errors gracefully' do
        params = ActionController::Parameters.new(prefill_fields: 'invalid-base64!')

        result = described_class.call(params)
        expect(result).to eq([])
      end
    end
  end

  describe 'VALID_FIELD_PATTERN' do
    it 'matches expected field patterns' do
      valid_patterns = %w[
        employee_first_name
        manager_last_name
        account_company_name
        location_street_address
      ]

      expect(valid_patterns).to all(match(described_class::VALID_FIELD_PATTERN))
    end

    it 'rejects invalid field patterns' do
      invalid_patterns = %w[
        invalid_field
        employee
        _employee_name
        employee_name_
        EMPLOYEE_NAME
        employee-name
        employee.name
        123_field
        field_123
      ]

      invalid_patterns.each do |pattern|
        expect(pattern).not_to match(described_class::VALID_FIELD_PATTERN)
      end
    end
  end
end
