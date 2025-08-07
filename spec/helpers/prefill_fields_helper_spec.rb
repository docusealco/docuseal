# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrefillFieldsHelper, type: :helper do
  describe '#extract_ats_prefill_fields' do
    it 'extracts valid field names from base64 encoded parameter' do
      fields = %w[employee_first_name employee_email manager_firstname]
      encoded = Base64.urlsafe_encode64(fields.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq(fields)
    end

    it 'returns empty array for invalid base64' do
      allow(helper).to receive(:params).and_return({ ats_fields: 'invalid_base64' })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'returns empty array for invalid JSON' do
      invalid_json = Base64.urlsafe_encode64('invalid json')
      allow(helper).to receive(:params).and_return({ ats_fields: invalid_json })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'filters out invalid field names' do
      fields = %w[employee_first_name malicious_field account_name invalid-field]
      encoded = Base64.urlsafe_encode64(fields.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq(%w[employee_first_name account_name])
    end

    it 'returns empty array when no ats_fields parameter' do
      allow(helper).to receive(:params).and_return({})

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'returns empty array when ats_fields parameter is empty' do
      allow(helper).to receive(:params).and_return({ ats_fields: '' })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'returns empty array when decoded JSON is not an array' do
      not_array = Base64.urlsafe_encode64({ field: 'employee_name' }.to_json)
      allow(helper).to receive(:params).and_return({ ats_fields: not_array })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'returns empty array when array contains non-string values' do
      mixed_array = ['employee_first_name', 123, 'manager_firstname']
      encoded = Base64.urlsafe_encode64(mixed_array.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'accepts all valid field name patterns' do
      fields = %w[
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
      encoded = Base64.urlsafe_encode64(fields.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq(fields)
    end

    it 'logs successful field reception' do
      fields = %w[employee_first_name employee_email]
      encoded = Base64.urlsafe_encode64(fields.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })
      allow(Rails.logger).to receive(:info)

      helper.extract_ats_prefill_fields

      expect(Rails.logger).to have_received(:info).with(
        'Received 2 ATS prefill fields: employee_first_name, employee_email'
      )
    end

    it 'logs parsing errors' do
      allow(helper).to receive(:params).and_return({ ats_fields: 'invalid_base64' })
      allow(Rails.logger).to receive(:warn)

      helper.extract_ats_prefill_fields

      expect(Rails.logger).to have_received(:warn).with(
        a_string_matching(/Failed to parse ATS prefill fields:/)
      )
    end
  end

  describe '#valid_ats_field_name?' do
    it 'returns true for valid employee field names' do
      expect(helper.send(:valid_ats_field_name?, 'employee_first_name')).to be true
      expect(helper.send(:valid_ats_field_name?, 'employee_email')).to be true
      expect(helper.send(:valid_ats_field_name?, 'employee_phone_number')).to be true
    end

    it 'returns true for valid manager field names' do
      expect(helper.send(:valid_ats_field_name?, 'manager_firstname')).to be true
      expect(helper.send(:valid_ats_field_name?, 'manager_lastname')).to be true
      expect(helper.send(:valid_ats_field_name?, 'manager_email')).to be true
    end

    it 'returns true for valid account field names' do
      expect(helper.send(:valid_ats_field_name?, 'account_name')).to be true
      expect(helper.send(:valid_ats_field_name?, 'account_id')).to be true
    end

    it 'returns true for valid location field names' do
      expect(helper.send(:valid_ats_field_name?, 'location_name')).to be true
      expect(helper.send(:valid_ats_field_name?, 'location_street')).to be true
      expect(helper.send(:valid_ats_field_name?, 'location_city')).to be true
    end

    it 'returns false for invalid field names' do
      expect(helper.send(:valid_ats_field_name?, 'malicious_field')).to be false
      expect(helper.send(:valid_ats_field_name?, 'invalid-field')).to be false
      expect(helper.send(:valid_ats_field_name?, 'EMPLOYEE_NAME')).to be false
      expect(helper.send(:valid_ats_field_name?, 'employee')).to be false
      expect(helper.send(:valid_ats_field_name?, 'employee_')).to be false
      expect(helper.send(:valid_ats_field_name?, '_employee_name')).to be false
    end
  end
end
