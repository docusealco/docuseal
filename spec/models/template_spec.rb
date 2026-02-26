# frozen_string_literal: true

RSpec.describe Template do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  describe '#unique_submitter_uuids' do
    it 'returns unique submitter UUIDs from fields' do
      template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
      template.update!(fields: [
                         { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                         { 'submitter_uuid' => 'uuid1', 'type' => 'signature' },
                         { 'submitter_uuid' => 'uuid2', 'type' => 'date' }
                       ])

      expect(template.unique_submitter_uuids).to match_array(%w[uuid1 uuid2])
    end

    it 'filters out nil submitter_uuids' do
      template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
      template.update!(fields: [
                         { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                         { 'submitter_uuid' => nil, 'type' => 'image' },
                         { 'type' => 'signature' }
                       ])

      expect(template.unique_submitter_uuids).to eq(['uuid1'])
    end

    it 'returns empty array when no fields' do
      template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
      template.update!(fields: [])

      expect(template.unique_submitter_uuids).to eq([])
    end
  end

  describe '#effective_submitters_order' do
    it 'returns preferences submitters_order when set' do
      template = create(:template, account:, author: user)
      template.update_column(:preferences, { 'submitters_order' => 'manager_then_employee' })

      expect(template.effective_submitters_order).to eq('manager_then_employee')
    end

    it 'returns single_sided when preferences not set and template has fewer than 2 unique submitters' do
      template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
      template.update_column(:preferences, {})
      template.update_column(:fields, [{ 'submitter_uuid' => 'uuid1', 'type' => 'text' }])

      expect(template.reload.effective_submitters_order).to eq('single_sided')
    end

    it 'returns employee_then_manager when preferences not set and template has 2+ unique submitters' do
      template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
      template.update_column(:preferences, {})
      template.update_column(:fields, [
                               { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                               { 'submitter_uuid' => 'uuid2', 'type' => 'signature' }
                             ])

      expect(template.reload.effective_submitters_order).to eq('employee_then_manager')
    end
  end

  describe '#update_submitters_order' do
    context 'when template has less than 2 unique submitters' do
      it 'sets submitters_order to single_sided' do
        template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
        template.update!(preferences: { 'submitters_order' => 'employee_then_manager' },
                         fields: [
                           { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                           { 'submitter_uuid' => 'uuid2', 'type' => 'signature' }
                         ])

        # Remove uuid2 fields to trigger single_sided
        template.update!(fields: [{ 'submitter_uuid' => 'uuid1', 'type' => 'text' }])

        expect(template.reload.preferences['submitters_order']).to eq('single_sided')
      end

      it 'always sets single_sided when only one unique submitter' do
        template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
        template.update!(fields: [{ 'submitter_uuid' => 'uuid1', 'type' => 'text' }])

        expect(template.reload.preferences['submitters_order']).to eq('single_sided')

        template.update!(fields: [{ 'submitter_uuid' => 'uuid1', 'type' => 'signature' }])

        expect(template.reload.preferences['submitters_order']).to eq('single_sided')
      end
    end

    context 'when template has 2 or more unique submitters' do
      it 'sets employee_then_manager when adding second submitter' do
        template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
        template.update!(preferences: { 'submitters_order' => 'single_sided' },
                         fields: [{ 'submitter_uuid' => 'uuid1', 'type' => 'text' }])

        # Add second submitter
        template.update!(fields: [
                           { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                           { 'submitter_uuid' => 'uuid2', 'type' => 'signature' }
                         ])

        expect(template.reload.preferences['submitters_order']).to eq('employee_then_manager')
      end

      it 'sets employee_then_manager when submitters_order is blank and 2 submitters added' do
        template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
        template.update!(fields: [
                           { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                           { 'submitter_uuid' => 'uuid2', 'type' => 'signature' }
                         ])

        expect(template.reload.preferences['submitters_order']).to eq('employee_then_manager')
      end

      it 'preserves employee_then_manager when multiple submitters' do
        template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
        template.update!(preferences: { 'submitters_order' => 'employee_then_manager' },
                         fields: [
                           { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                           { 'submitter_uuid' => 'uuid2', 'type' => 'signature' }
                         ])

        template.update!(fields: [
                           { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                           { 'submitter_uuid' => 'uuid2', 'type' => 'signature' },
                           { 'submitter_uuid' => 'uuid1', 'type' => 'date' }
                         ])

        expect(template.reload.preferences['submitters_order']).to eq('employee_then_manager')
      end
    end

    context 'when removing fields transitions from multi to single submitter' do
      it 'changes from employee_then_manager to single_sided' do
        template = create(:template, account:, author: user, submitter_count: 0, attachment_count: 0)
        template.update!(preferences: { 'submitters_order' => 'employee_then_manager' },
                         fields: [
                           { 'submitter_uuid' => 'uuid1', 'type' => 'text' },
                           { 'submitter_uuid' => 'uuid2', 'type' => 'signature' }
                         ])

        # Remove all uuid2 fields
        template.update!(fields: [{ 'submitter_uuid' => 'uuid1', 'type' => 'text' }])

        expect(template.reload.preferences['submitters_order']).to eq('single_sided')
      end
    end
  end
end
