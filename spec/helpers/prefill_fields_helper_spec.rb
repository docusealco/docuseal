# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrefillFieldsHelper, type: :helper do
  let(:template_fields) do
    [
      {
        'uuid' => 'field-1-uuid',
        'name' => 'First Name',
        'type' => 'text',
        'prefill' => 'employee_first_name'
      },
      {
        'uuid' => 'field-2-uuid',
        'name' => 'Last Name',
        'type' => 'text',
        'prefill' => 'employee_last_name'
      },
      {
        'uuid' => 'field-3-uuid',
        'name' => 'Email',
        'type' => 'text',
        'prefill' => 'employee_email'
      },
      {
        'uuid' => 'field-4-uuid',
        'name' => 'Signature',
        'type' => 'signature'
        # No prefill attribute
      }
    ]
  end

  describe '#find_field_uuid_by_name' do
    context 'when template_fields is provided' do
      it 'returns the correct UUID for a matching ATS field name' do
        uuid = helper.send(:find_field_uuid_by_name, 'employee_first_name', template_fields)
        expect(uuid).to eq('field-1-uuid')
      end

      it 'returns the correct UUID for another matching ATS field name' do
        uuid = helper.send(:find_field_uuid_by_name, 'employee_email', template_fields)
        expect(uuid).to eq('field-3-uuid')
      end

      it 'returns nil for a non-matching ATS field name' do
        uuid = helper.send(:find_field_uuid_by_name, 'non_existent_field', template_fields)
        expect(uuid).to be_nil
      end

      it 'returns nil for a field without prefill attribute' do
        uuid = helper.send(:find_field_uuid_by_name, 'signature', template_fields)
        expect(uuid).to be_nil
      end
    end

    context 'when template_fields is nil' do
      it 'returns nil' do
        uuid = helper.send(:find_field_uuid_by_name, 'employee_first_name', nil)
        expect(uuid).to be_nil
      end
    end

    context 'when template_fields is empty' do
      it 'returns nil' do
        uuid = helper.send(:find_field_uuid_by_name, 'employee_first_name', [])
        expect(uuid).to be_nil
      end
    end

    context 'when field_name is blank' do
      it 'returns nil for nil field_name' do
        uuid = helper.send(:find_field_uuid_by_name, nil, template_fields)
        expect(uuid).to be_nil
      end

      it 'returns nil for empty field_name' do
        uuid = helper.send(:find_field_uuid_by_name, '', template_fields)
        expect(uuid).to be_nil
      end
    end
  end

  describe '#merge_prefill_values' do
    let(:submitter_values) do
      {
        'field-1-uuid' => 'Existing First Name',
        'field-4-uuid' => 'Existing Signature'
      }
    end

    let(:prefill_values) do
      {
        'employee_first_name' => 'John',
        'employee_last_name' => 'Doe',
        'employee_email' => 'john.doe@example.com'
      }
    end

    context 'when template_fields is provided' do
      it 'merges ATS values for fields that do not have existing submitter values' do
        result = helper.merge_prefill_values(submitter_values, prefill_values, template_fields)

        expect(result).to include(
          'field-1-uuid' => 'Existing First Name', # Should not be overwritten
          'field-2-uuid' => 'Doe',                 # Should be set from ATS
          'field-3-uuid' => 'john.doe@example.com', # Should be set from ATS
          'field-4-uuid' => 'Existing Signature' # Should remain unchanged
        )
      end

      it 'does not overwrite existing submitter values' do
        result = helper.merge_prefill_values(submitter_values, prefill_values, template_fields)

        expect(result['field-1-uuid']).to eq('Existing First Name')
      end

      it 'ignores ATS values for fields without matching prefill attributes' do
        prefill_values_with_unknown = prefill_values.merge('unknown_field' => 'Unknown Value')

        result = helper.merge_prefill_values(submitter_values, prefill_values_with_unknown, template_fields)

        expect(result.keys).not_to include('unknown_field')
      end
    end

    context 'when template_fields is nil' do
      it 'returns original submitter_values unchanged' do
        result = helper.merge_prefill_values(submitter_values, prefill_values, nil)
        expect(result).to eq(submitter_values)
      end
    end

    context 'when prefill_values is blank' do
      it 'returns original submitter_values for nil prefill_values' do
        result = helper.merge_prefill_values(submitter_values, nil, template_fields)
        expect(result).to eq(submitter_values)
      end

      it 'returns original submitter_values for empty prefill_values' do
        result = helper.merge_prefill_values(submitter_values, {}, template_fields)
        expect(result).to eq(submitter_values)
      end
    end

    context 'when submitter_values has blank values' do
      let(:submitter_values_with_blanks) do
        {
          'field-1-uuid' => '',
          'field-2-uuid' => nil,
          'field-4-uuid' => 'Existing Signature'
        }
      end

      it 'fills blank submitter values with ATS values' do
        result = helper.merge_prefill_values(submitter_values_with_blanks, prefill_values, template_fields)

        expect(result).to include(
          'field-1-uuid' => 'John',                 # Should be filled from ATS (was blank)
          'field-2-uuid' => 'Doe',                  # Should be filled from ATS (was nil)
          'field-3-uuid' => 'john.doe@example.com', # Should be set from ATS (was missing)
          'field-4-uuid' => 'Existing Signature'    # Should remain unchanged
        )
      end
    end
  end

  describe '#extract_prefill_fields' do
    before do
      allow(helper).to receive(:params).and_return(params)
    end

    context 'when prefill_fields parameter is present' do
      let(:fields) { %w[employee_first_name employee_last_name employee_email] }
      let(:encoded_fields) { Base64.urlsafe_encode64(fields.to_json) }
      let(:params) { { prefill_fields: encoded_fields } }

      it 'decodes and returns the ATS fields' do
        result = helper.extract_prefill_fields
        expect(result).to eq(fields)
      end

      it 'caches the result' do
        # The implementation now uses AtsPrefill service which uses Rails.cache.fetch
        cache_key = Prefill::CacheManager.generate_cache_key('prefill_fields', encoded_fields)

        # Mock the cache to verify it's being used
        allow(Rails.cache).to receive(:fetch).and_call_original

        helper.extract_prefill_fields

        expect(Rails.cache).to have_received(:fetch).with(cache_key, expires_in: 3600)
      end
    end

    context 'when prefill_fields parameter is missing' do
      let(:params) { {} }

      it 'returns an empty array' do
        result = helper.extract_prefill_fields
        expect(result).to eq([])
      end
    end

    context 'when prefill_fields parameter is invalid' do
      let(:params) { { prefill_fields: 'invalid-base64' } }

      it 'returns an empty array' do
        result = helper.extract_prefill_fields
        expect(result).to eq([])
      end
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

      allow(helper).to receive(:params).and_return({ prefill_fields: encoded })

      result = helper.extract_prefill_fields
      expect(result).to eq(fields)
    end
  end
end
