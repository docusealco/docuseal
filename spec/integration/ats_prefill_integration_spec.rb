# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ATS Prefill Integration', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:template_folder) { create(:template_folder, account: account) }

  let(:template_fields) do
    [
      {
        'uuid' => 'field-1-uuid',
        'name' => 'First Name',
        'type' => 'text',
        'prefill' => 'employee_first_name',
        'submitter_uuid' => 'submitter-uuid-1'
      },
      {
        'uuid' => 'field-2-uuid',
        'name' => 'Last Name',
        'type' => 'text',
        'prefill' => 'employee_last_name',
        'submitter_uuid' => 'submitter-uuid-1'
      },
      {
        'uuid' => 'field-3-uuid',
        'name' => 'Email',
        'type' => 'text',
        'prefill' => 'employee_email',
        'submitter_uuid' => 'submitter-uuid-1'
      },
      {
        'uuid' => 'field-4-uuid',
        'name' => 'Signature',
        'type' => 'signature',
        'submitter_uuid' => 'submitter-uuid-1'
      }
    ]
  end

  let(:template) do
    create(:template,
           account: account,
           author: user,
           folder: template_folder,
           fields: template_fields,
           submitters: [{ 'name' => 'First Party', 'uuid' => 'submitter-uuid-1' }])
  end

  let(:submission) do
    create(:submission,
           template: template,
           account: account,
           created_by_user: user,
           template_fields: template_fields,
           template_submitters: [{ 'name' => 'First Party', 'uuid' => 'submitter-uuid-1' }])
  end

  let(:submitter) do
    create(:submitter,
           submission: submission,
           uuid: 'submitter-uuid-1',
           name: 'John Doe',
           email: 'john@example.com')
  end

  describe 'Controller ATS parameter processing' do
    let(:controller) { SubmitFormController.new }

    before do
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(test_params))
    end

    context 'when ATS fields and values are provided via Base64 parameters' do
      let(:test_params) do
        {
          ats_fields: Base64.urlsafe_encode64(%w[employee_first_name employee_last_name employee_email].to_json),
          ats_values: Base64.urlsafe_encode64({ 'employee_first_name' => 'John', 'employee_last_name' => 'Smith',
                                                'employee_email' => 'john.smith@company.com' }.to_json)
        }
      end

      it 'successfully decodes and processes ATS parameters' do
        result = controller.send(:fetch_ats_prefill_values_if_available)

        expect(result).to eq({
                               'employee_first_name' => 'John',
                               'employee_last_name' => 'Smith',
                               'employee_email' => 'john.smith@company.com'
                             })
      end
    end

    context 'when ats_values parameter contains invalid Base64' do
      let(:test_params) do
        {
          ats_fields: Base64.urlsafe_encode64(['employee_first_name'].to_json),
          ats_values: 'invalid-base64!'
        }
      end

      it 'handles Base64 decoding errors gracefully' do
        result = controller.send(:fetch_ats_prefill_values_if_available)
        expect(result).to eq({})
      end
    end

    context 'when ats_values parameter contains valid Base64 but invalid JSON' do
      let(:test_params) do
        {
          ats_fields: Base64.urlsafe_encode64(['employee_first_name'].to_json),
          ats_values: Base64.urlsafe_encode64('invalid json')
        }
      end

      it 'handles JSON parsing errors gracefully' do
        result = controller.send(:fetch_ats_prefill_values_if_available)
        expect(result).to eq({})
      end
    end

    context 'when ats_values parameter contains valid JSON but wrong data type' do
      let(:test_params) do
        {
          ats_fields: Base64.urlsafe_encode64(['employee_first_name'].to_json),
          ats_values: Base64.urlsafe_encode64('["not", "a", "hash"]')
        }
      end

      it 'handles invalid data type gracefully' do
        result = controller.send(:fetch_ats_prefill_values_if_available)
        expect(result).to eq({})
      end
    end

    context 'when no ATS parameters are provided' do
      let(:test_params) { {} }

      it 'returns empty hash when no ATS parameters present' do
        result = controller.send(:fetch_ats_prefill_values_if_available)
        expect(result).to eq({})
      end
    end
  end

  describe 'Helper method integration' do
    include PrefillFieldsHelper

    it 'correctly maps ATS field names to template field UUIDs' do
      result = find_field_uuid_by_name('employee_first_name', template_fields)
      expect(result).to eq('field-1-uuid')

      result = find_field_uuid_by_name('employee_last_name', template_fields)
      expect(result).to eq('field-2-uuid')

      result = find_field_uuid_by_name('nonexistent_field', template_fields)
      expect(result).to be_nil
    end

    it 'correctly merges ATS values with existing submitter values' do
      existing_values = { 'field-1-uuid' => 'Existing John' }
      ats_values = { 'employee_first_name' => 'ATS John', 'employee_last_name' => 'ATS Smith' }

      result = merge_ats_prefill_values(existing_values, ats_values, template_fields)

      expect(result).to eq({
                             'field-1-uuid' => 'Existing John', # Should not override existing value
                             'field-2-uuid' => 'ATS Smith' # Should add new ATS value
                           })
    end

    it 'handles empty ATS values gracefully' do
      existing_values = { 'field-1-uuid' => 'Existing John' }
      ats_values = {}

      result = merge_ats_prefill_values(existing_values, ats_values, template_fields)

      expect(result).to eq({
                             'field-1-uuid' => 'Existing John'
                           })
    end

    it 'handles missing template fields gracefully' do
      existing_values = {}
      ats_values = { 'nonexistent_field' => 'Some Value' }

      result = merge_ats_prefill_values(existing_values, ats_values, template_fields)

      expect(result).to eq({})
    end
  end

  describe 'End-to-end ATS prefill workflow' do
    include PrefillFieldsHelper

    it 'processes complete ATS prefill workflow from parameters to merged values' do
      # Step 1: Simulate controller parameter processing
      controller = SubmitFormController.new
      ats_fields_data = %w[employee_first_name employee_last_name employee_email]
      ats_values_data = {
        'employee_first_name' => 'John',
        'employee_last_name' => 'Smith',
        'employee_email' => 'john.smith@company.com'
      }

      encoded_fields = Base64.urlsafe_encode64(ats_fields_data.to_json)
      encoded_values = Base64.urlsafe_encode64(ats_values_data.to_json)

      params = ActionController::Parameters.new({
                                                  ats_fields: encoded_fields,
                                                  ats_values: encoded_values
                                                })

      allow(controller).to receive(:params).and_return(params)

      ats_values = controller.send(:fetch_ats_prefill_values_if_available)

      # Step 2: Simulate existing submitter values
      existing_submitter_values = { 'field-1-uuid' => 'Existing John' }

      # Step 3: Merge ATS values with existing values
      final_values = merge_ats_prefill_values(existing_submitter_values, ats_values, template_fields)

      # Step 4: Verify final result
      expect(final_values).to eq({
                                   'field-1-uuid' => 'Existing John', # Existing value preserved
                                   'field-2-uuid' => 'Smith',                           # ATS value applied
                                   'field-3-uuid' => 'john.smith@company.com'           # ATS value applied
                                 })
    end
  end
end
