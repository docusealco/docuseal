# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Prefill do
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
      }
    ]
  end

  describe '.extract_fields' do
    let(:params) { ActionController::Parameters.new(prefill_fields: 'encoded_data') }

    it 'delegates to FieldExtractor' do
      expected_result = %w[employee_first_name employee_last_name]

      allow(Prefill::FieldExtractor).to receive(:call).with(params).and_return(expected_result)

      result = described_class.extract_fields(params)
      expect(result).to eq(expected_result)
    end
  end

  describe '.merge_values' do
    let(:submitter_values) { { 'field-1-uuid' => 'John' } }
    let(:prefill_values) { { 'employee_last_name' => 'Doe' } }

    it 'delegates to ValueMerger' do
      expected_result = { 'field-1-uuid' => 'John', 'field-2-uuid' => 'Doe' }

      allow(Prefill::ValueMerger).to receive(:call).with(submitter_values, prefill_values,
                                                         template_fields).and_return(expected_result)

      result = described_class.merge_values(submitter_values, prefill_values, template_fields)
      expect(result).to eq(expected_result)
    end

    it 'handles nil template_fields' do
      allow(Prefill::ValueMerger).to receive(:call).with(submitter_values, prefill_values,
                                                         nil).and_return(submitter_values)

      result = described_class.merge_values(submitter_values, prefill_values, nil)
      expect(result).to eq(submitter_values)
    end
  end

  describe '.find_field_uuid' do
    let(:field_name) { 'employee_first_name' }

    it 'delegates to FieldMapper.find_field_uuid' do
      expected_uuid = 'field-1-uuid'

      allow(Prefill::FieldMapper).to receive(:find_field_uuid).with(field_name,
                                                                    template_fields).and_return(expected_uuid)

      result = described_class.find_field_uuid(field_name, template_fields)
      expect(result).to eq(expected_uuid)
    end

    it 'returns nil for non-existent field' do
      allow(Prefill::FieldMapper).to receive(:find_field_uuid).with('non_existent', template_fields).and_return(nil)

      result = described_class.find_field_uuid('non_existent', template_fields)
      expect(result).to be_nil
    end
  end

  describe '.build_field_mapping' do
    it 'delegates to FieldMapper.call' do
      expected_mapping = { 'employee_first_name' => 'field-1-uuid', 'employee_last_name' => 'field-2-uuid' }

      allow(Prefill::FieldMapper).to receive(:call).with(template_fields).and_return(expected_mapping)

      result = described_class.build_field_mapping(template_fields)
      expect(result).to eq(expected_mapping)
    end

    it 'handles nil template_fields' do
      allow(Prefill::FieldMapper).to receive(:call).with(nil).and_return({})

      result = described_class.build_field_mapping(nil)
      expect(result).to eq({})
    end
  end

  describe '.clear_cache' do
    it 'exists as a method for future use' do
      expect { described_class.clear_cache }.not_to raise_error
    end

    it 'returns nil' do
      result = described_class.clear_cache
      expect(result).to be_nil
    end
  end

  describe 'integration test' do
    let(:params) do
      fields = %w[employee_first_name employee_last_name]
      encoded_fields = Base64.urlsafe_encode64(fields.to_json)
      ActionController::Parameters.new(prefill_fields: encoded_fields)
    end

    let(:submitter_values) { { 'field-1-uuid' => 'Existing Name' } }
    let(:prefill_values) { { 'employee_first_name' => 'John', 'employee_last_name' => 'Doe' } }

    it 'works end-to-end with real service objects' do
      # Extract fields
      extracted_fields = described_class.extract_fields(params)
      expect(extracted_fields).to eq(%w[employee_first_name employee_last_name])

      # Build field mapping
      field_mapping = described_class.build_field_mapping(template_fields)
      expect(field_mapping).to eq({
                                    'employee_first_name' => 'field-1-uuid',
                                    'employee_last_name' => 'field-2-uuid'
                                  })

      # Find specific field UUID
      uuid = described_class.find_field_uuid('employee_first_name', template_fields)
      expect(uuid).to eq('field-1-uuid')

      # Merge values
      merged_values = described_class.merge_values(submitter_values, prefill_values, template_fields)
      expect(merged_values).to eq({
                                    'field-1-uuid' => 'Existing Name', # Should not be overwritten
                                    'field-2-uuid' => 'Doe' # Should be added from prefill
                                  })
    end
  end

  describe 'module structure' do
    it 'includes all expected methods' do
      expected_methods = %i[
        extract_fields
        merge_values
        find_field_uuid
        build_field_mapping
        clear_cache
      ]

      expected_methods.each do |method|
        expect(described_class).to respond_to(method)
      end
    end

    it 'is a module with module_function' do
      expect(described_class).to be_a(Module)

      # Check that methods are available as module methods
      expect(described_class).to respond_to(:extract_fields)
      expect(described_class.methods).to include(:extract_fields)
    end
  end

  describe 'error handling' do
    it 'propagates errors from underlying services' do
      allow(Prefill::FieldExtractor).to receive(:call).and_raise(StandardError, 'Test error')

      expect { described_class.extract_fields({}) }.to raise_error(StandardError, 'Test error')
    end
  end
end
