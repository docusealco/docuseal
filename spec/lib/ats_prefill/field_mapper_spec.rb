# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AtsPrefill::FieldMapper do
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

  describe '.call' do
    context 'when template_fields is provided' do
      it 'returns correct mapping of prefill names to UUIDs' do
        result = described_class.call(template_fields)

        expect(result).to eq({
                               'employee_first_name' => 'field-1-uuid',
                               'employee_last_name' => 'field-2-uuid',
                               'employee_email' => 'field-3-uuid'
                             })
      end

      it 'excludes fields without prefill attributes' do
        result = described_class.call(template_fields)

        expect(result).not_to have_key('signature')
        expect(result.values).not_to include('field-4-uuid')
      end

      it 'caches the result' do
        cache_signature = template_fields
                          .filter_map do |f|
          "#{f['uuid']}:#{f['prefill']}" if f['uuid'].present? && f['prefill'].present?
        end
                          .sort
                          .join('|')
        cache_key = AtsPrefill::CacheManager.generate_cache_key('field_mapping', cache_signature)

        allow(AtsPrefill::CacheManager).to receive(:fetch_field_mapping).and_call_original

        described_class.call(template_fields)

        expect(AtsPrefill::CacheManager).to have_received(:fetch_field_mapping).with(cache_key)
      end

      it 'returns cached result on subsequent calls' do
        cache_signature = template_fields
                          .filter_map do |f|
          "#{f['uuid']}:#{f['prefill']}" if f['uuid'].present? && f['prefill'].present?
        end
                          .sort
                          .join('|')
        cache_key = AtsPrefill::CacheManager.generate_cache_key('field_mapping', cache_signature)
        cached_result = { 'cached_field' => 'cached_uuid' }

        allow(AtsPrefill::CacheManager).to receive(:fetch_field_mapping).with(cache_key).and_return(cached_result)

        result = described_class.call(template_fields)
        expect(result).to eq(cached_result)
      end
    end

    context 'when template_fields is nil' do
      it 'returns empty hash' do
        result = described_class.call(nil)
        expect(result).to eq({})
      end
    end

    context 'when template_fields is empty' do
      it 'returns empty hash' do
        result = described_class.call([])
        expect(result).to eq({})
      end
    end

    context 'when fields have missing attributes' do
      let(:incomplete_fields) do
        [
          {
            'uuid' => 'field-1-uuid',
            'prefill' => 'employee_first_name'
          },
          {
            'uuid' => 'field-2-uuid'
            # Missing prefill
          },
          {
            'prefill' => 'employee_last_name'
            # Missing uuid
          },
          {
            'uuid' => '',
            'prefill' => 'employee_email'
          },
          {
            'uuid' => 'field-5-uuid',
            'prefill' => ''
          }
        ]
      end

      it 'only includes fields with both uuid and prefill present' do
        result = described_class.call(incomplete_fields)

        expect(result).to eq({
                               'employee_first_name' => 'field-1-uuid'
                             })
      end
    end

    context 'with duplicate prefill names' do
      let(:duplicate_fields) do
        [
          {
            'uuid' => 'field-1-uuid',
            'prefill' => 'employee_name'
          },
          {
            'uuid' => 'field-2-uuid',
            'prefill' => 'employee_name'
          }
        ]
      end

      it 'uses the last occurrence for duplicate prefill names' do
        result = described_class.call(duplicate_fields)

        expect(result).to eq({
                               'employee_name' => 'field-2-uuid'
                             })
      end
    end
  end

  describe '.find_field_uuid' do
    context 'when template_fields is provided' do
      it 'returns the correct UUID for a matching ATS field name' do
        uuid = described_class.find_field_uuid('employee_first_name', template_fields)
        expect(uuid).to eq('field-1-uuid')
      end

      it 'returns the correct UUID for another matching ATS field name' do
        uuid = described_class.find_field_uuid('employee_email', template_fields)
        expect(uuid).to eq('field-3-uuid')
      end

      it 'returns nil for a non-matching ATS field name' do
        uuid = described_class.find_field_uuid('non_existent_field', template_fields)
        expect(uuid).to be_nil
      end

      it 'returns nil for a field without prefill attribute' do
        uuid = described_class.find_field_uuid('signature', template_fields)
        expect(uuid).to be_nil
      end

      it 'uses the cached field mapping' do
        allow(described_class).to receive(:call).with(template_fields).and_return(
          { 'employee_first_name' => 'field-1-uuid' }
        )

        uuid = described_class.find_field_uuid('employee_first_name',
                                               template_fields)
        expect(uuid).to eq('field-1-uuid')
      end
    end

    context 'when template_fields is nil' do
      it 'returns nil' do
        uuid = described_class.find_field_uuid('employee_first_name', nil)
        expect(uuid).to be_nil
      end
    end

    context 'when template_fields is empty' do
      it 'returns nil' do
        uuid = described_class.find_field_uuid('employee_first_name', [])
        expect(uuid).to be_nil
      end
    end

    context 'when field_name is blank' do
      it 'returns nil for nil field_name' do
        uuid = described_class.find_field_uuid(nil, template_fields)
        expect(uuid).to be_nil
      end

      it 'returns nil for empty field_name' do
        uuid = described_class.find_field_uuid('', template_fields)
        expect(uuid).to be_nil
      end
    end
  end

  describe 'cache signature generation' do
    it 'generates consistent cache signatures' do
      signature1 = described_class.send(:build_cache_signature, template_fields)
      signature2 = described_class.send(:build_cache_signature, template_fields)

      expect(signature1).to eq(signature2)
    end

    it 'generates different signatures for different field sets' do
      different_fields = [
        {
          'uuid' => 'different-uuid',
          'prefill' => 'different_field'
        }
      ]

      signature1 = described_class.send(:build_cache_signature, template_fields)
      signature2 = described_class.send(:build_cache_signature, different_fields)

      expect(signature1).not_to eq(signature2)
    end

    it 'generates same signature regardless of field order' do
      shuffled_fields = template_fields.shuffle

      signature1 = described_class.send(:build_cache_signature, template_fields)
      signature2 = described_class.send(:build_cache_signature, shuffled_fields)

      expect(signature1).to eq(signature2)
    end
  end
end
