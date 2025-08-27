# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AtsPrefill::ValueMerger do
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
    let(:submitter_values) do
      {
        'field-1-uuid' => 'Existing First Name',
        'field-4-uuid' => 'Existing Signature'
      }
    end

    let(:ats_values) do
      {
        'employee_first_name' => 'John',
        'employee_last_name' => 'Doe',
        'employee_email' => 'john.doe@example.com'
      }
    end

    context 'when template_fields is provided' do
      it 'merges ATS values for fields that do not have existing submitter values' do
        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result).to include(
          'field-1-uuid' => 'Existing First Name', # Should not be overwritten
          'field-2-uuid' => 'Doe',                 # Should be set from ATS
          'field-3-uuid' => 'john.doe@example.com', # Should be set from ATS
          'field-4-uuid' => 'Existing Signature' # Should remain unchanged
        )
      end

      it 'does not overwrite existing submitter values' do
        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result['field-1-uuid']).to eq('Existing First Name')
      end

      it 'ignores ATS values for fields without matching prefill attributes' do
        ats_values_with_unknown = ats_values.merge('unknown_field' => 'Unknown Value')

        result = described_class.call(submitter_values, ats_values_with_unknown, template_fields)

        expect(result.keys).not_to include('unknown_field')
      end

      it 'uses FieldMapper to get field mapping' do
        expected_mapping = {
          'employee_first_name' => 'field-1-uuid',
          'employee_last_name' => 'field-2-uuid',
          'employee_email' => 'field-3-uuid'
        }

        allow(AtsPrefill::FieldMapper).to receive(:call).and_return(expected_mapping)

        described_class.call(submitter_values, ats_values, template_fields)

        expect(AtsPrefill::FieldMapper).to have_received(:call).with(template_fields)
      end
    end

    context 'when template_fields is nil' do
      it 'returns original submitter_values unchanged' do
        result = described_class.call(submitter_values, ats_values, nil)
        expect(result).to eq(submitter_values)
      end
    end

    context 'when ats_values is blank' do
      it 'returns original submitter_values for nil ats_values' do
        result = described_class.call(submitter_values, nil, template_fields)
        expect(result).to eq(submitter_values)
      end

      it 'returns original submitter_values for empty ats_values' do
        result = described_class.call(submitter_values, {}, template_fields)
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
        result = described_class.call(submitter_values_with_blanks, ats_values, template_fields)

        expect(result).to include(
          'field-1-uuid' => 'John',                 # Should be filled from ATS (was blank)
          'field-2-uuid' => 'Doe',                  # Should be filled from ATS (was nil)
          'field-3-uuid' => 'john.doe@example.com', # Should be set from ATS (was missing)
          'field-4-uuid' => 'Existing Signature'    # Should remain unchanged
        )
      end

      it 'treats empty string as blank' do
        submitter_values = { 'field-1-uuid' => '' }
        ats_values = { 'employee_first_name' => 'John' }

        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result['field-1-uuid']).to eq('John')
      end

      it 'treats nil as blank' do
        submitter_values = { 'field-1-uuid' => nil }
        ats_values = { 'employee_first_name' => 'John' }

        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result['field-1-uuid']).to eq('John')
      end

      it 'does not treat false as blank' do
        submitter_values = { 'field-1-uuid' => false }
        ats_values = { 'employee_first_name' => 'John' }

        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result['field-1-uuid']).to be(false)
      end

      it 'does not treat zero as blank' do
        submitter_values = { 'field-1-uuid' => 0 }
        ats_values = { 'employee_first_name' => 'John' }

        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result['field-1-uuid']).to eq(0)
      end
    end

    context 'when field mapping is empty' do
      it 'returns original submitter values when no fields match' do
        allow(AtsPrefill::FieldMapper).to receive(:call).and_return({})

        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result).to eq(submitter_values)
      end
    end

    context 'with complex scenarios' do
      it 'handles multiple ATS values with partial existing submitter values' do
        submitter_values = {
          'field-1-uuid' => 'Keep This',
          'field-2-uuid' => '',
          'field-5-uuid' => 'Unrelated Field'
        }

        ats_values = {
          'employee_first_name' => 'Should Not Override',
          'employee_last_name' => 'Should Fill',
          'employee_email' => 'Should Add',
          'unknown_field' => 'Should Ignore'
        }

        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result).to eq({
                               'field-1-uuid' => 'Keep This',
                               'field-2-uuid' => 'Should Fill',
                               'field-3-uuid' => 'Should Add',
                               'field-5-uuid' => 'Unrelated Field'
                             })
      end

      it 'modifies the original submitter_values hash' do
        original_values = submitter_values.dup

        result = described_class.call(submitter_values, ats_values, template_fields)

        expect(result).to be(submitter_values)
        expect(submitter_values).not_to eq(original_values)
      end
    end
  end
end
