# frozen_string_literal: true

describe Templates::CloneToPartnership do
  let(:account) { create(:account) }
  let(:partnership) { create(:partnership) }
  let(:global_partnership) { create(:partnership) }
  let(:user) { create(:user, account: account) }

  before do
    allow(ExportLocation).to receive(:global_partnership_id).and_return(global_partnership.id)
  end

  describe '.call' do
    context 'with global partnership template' do
      let(:template) do
        create(:template, :partnership_template, partnership: global_partnership, name: 'Original Template')
      end

      it 'clones template to partnership' do
        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result).to be_a(Template)
        expect(result.partnership_id).to eq(partnership.id)
        expect(result.account_id).to be_nil
        expect(result.name).to eq('Original Template (Clone)')
        expect(result.id).not_to eq(template.id)
      end

      it 'copies template attributes' do
        template.update!(
          preferences: { 'test' => 'value' },
          external_data_fields: { 'field' => 'data' }
        )

        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result.preferences).to eq(template.preferences)
        expect(result.external_data_fields).to eq({})
      end

      it 'copies submitters' do
        # Add a submitter to the template's submitters array
        submitter_uuid = SecureRandom.uuid
        template.submitters = [{
          'uuid' => submitter_uuid,
          'name' => 'Test Submitter'
        }]
        template.save!

        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result.submitters.count).to eq(1)
        expect(result.submitters.first['name']).to eq('Test Submitter')
        expect(result.submitters.first['uuid']).not_to eq(submitter_uuid)
      end

      it 'copies fields' do
        # Add a field to the template's fields array
        field_uuid = SecureRandom.uuid
        template.fields = [{
          'uuid' => field_uuid,
          'name' => 'Test Field',
          'type' => 'text',
          'required' => true
        }]
        template.save!

        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result.fields.count).to eq(1)
        expect(result.fields.first['name']).to eq('Test Field')
        expect(result.fields.first['uuid']).not_to eq(field_uuid)
      end
    end

    context 'with partnership template' do
      let(:template) do
        create(:template, :partnership_template, partnership: global_partnership, name: 'Partnership Template')
      end

      it 'clones template to different partnership' do
        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result.partnership_id).to eq(partnership.id)
        expect(result.partnership_id).not_to eq(global_partnership.id)
        expect(result.account_id).to be_nil
        expect(result.name).to eq('Partnership Template (Clone)')
      end
    end

    context 'with external_id' do
      let(:template) do
        create(:template, :partnership_template, partnership: global_partnership, name: 'Global Template')
      end

      it 'sets external_id when provided' do
        result = described_class.call(template, author: user, target_partnership: partnership,
                                                external_id: 'custom-123')

        expect(result.external_id).to eq('custom-123')
      end

      it 'does not set external_id when not provided' do
        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result.external_id).to be_nil
      end
    end

    context 'with author' do
      let(:template) do
        create(:template, :partnership_template, partnership: global_partnership, name: 'Global Template')
      end

      it 'sets author when provided' do
        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result.author).to eq(user)
      end

      it 'uses provided author' do
        original_author = create(:user, :with_partnership)
        template.update!(author: original_author)

        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result.author).to eq(user)
      end
    end

    context 'when handling errors' do
      let(:template) do
        create(:template, :partnership_template, partnership: global_partnership, name: 'Global Template')
      end

      it 'raises error if partnership is nil' do
        expect do
          described_class.call(template, author: user, target_partnership: nil)
        end.to raise_error(ArgumentError)
      end
    end

    context 'with complex template structure' do
      let(:template) do
        create(:template, :partnership_template, partnership: global_partnership, name: 'Global Template')
      end

      before do
        # Create a complex template with multiple submitters and fields
        template.submitters = [
          { 'uuid' => SecureRandom.uuid, 'name' => 'Submitter 1' },
          { 'uuid' => SecureRandom.uuid, 'name' => 'Submitter 2' }
        ]
        template.fields = [
          { 'uuid' => SecureRandom.uuid, 'name' => 'Field 1', 'type' => 'text' },
          { 'uuid' => SecureRandom.uuid, 'name' => 'Field 2', 'type' => 'signature' }
        ]
        template.save!
      end

      it 'clones all components correctly' do
        result = described_class.call(template, author: user, target_partnership: partnership)

        expect(result.submitters.count).to eq(2)
        expect(result.fields.count).to eq(2)
        expect(result.submitters.pluck('name')).to contain_exactly('Submitter 1', 'Submitter 2')
        expect(result.fields.pluck('name')).to contain_exactly('Field 1', 'Field 2')
      end
    end
  end
end
