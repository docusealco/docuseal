# frozen_string_literal: true

require 'rails_helper'
require 'templates/field_detection'
require 'templates/field_detection/config_based'

RSpec.describe Templates::FieldDetection::ConfigBased do
  let(:user) { create(:user) }
  let(:template) { create(:template, account: user.account, author: user) }
  let(:attachment) { template.schema_documents.first }
  let(:documents) { template.schema_documents.preload(:blob) }

  describe '.call' do
    context 'with absolute position fields' do
      let(:config) do
        {
          'submitters' => [{ 'name' => 'signer' }],
          'fields' => [
            {
              'name' => 'full-name',
              'type' => 'text',
              'submitter' => 'signer',
              'required' => true,
              'position' => { 'page' => 0, 'x' => 0.10, 'y' => 0.20, 'w' => 0.30, 'h' => 0.04 }
            }
          ]
        }
      end

      it 'places fields at absolute coordinates' do
        fields = described_class.call(template, config, documents)

        expect(fields.length).to eq(1)
        field = fields.first
        expect(field['name']).to eq('full-name')
        expect(field['type']).to eq('text')
        expect(field['required']).to be(true)
        expect(field['areas'].first['page']).to eq(0)
        expect(field['areas'].first['x']).to be_within(0.001).of(0.10)
        expect(field['areas'].first['y']).to be_within(0.001).of(0.20)
        expect(field['areas'].first['w']).to be_within(0.001).of(0.30)
        expect(field['areas'].first['h']).to be_within(0.001).of(0.04)
      end

      it 'saves fields to the template' do
        described_class.call(template, config, documents)
        template.reload

        expect(template.fields.length).to eq(1)
        expect(template.fields.first['name']).to eq('full-name')
      end

      it 'assigns submitter_uuid from the config submitter map' do
        fields = described_class.call(template, config, documents)

        signer = template.submitters.find { |s| s['name'].downcase == 'signer' }
        expect(signer).to be_present
        expect(fields.first['submitter_uuid']).to eq(signer['uuid'])
      end
    end

    context 'with negative page index' do
      let(:config) do
        {
          'submitters' => [{ 'name' => 'signer' }],
          'fields' => [
            {
              'name' => 'last-page-sig',
              'type' => 'signature',
              'submitter' => 'signer',
              'position' => { 'page' => -1, 'x' => 0.50, 'y' => 0.80, 'w' => 0.25, 'h' => 0.05 }
            }
          ]
        }
      end

      it 'resolves -1 to the last page' do
        fields = described_class.call(template, config, documents)

        expect(fields.length).to eq(1)
        area = fields.first['areas'].first
        expect(area['page']).to be >= 0
      end
    end

    context 'with unknown submitter role' do
      let(:config) do
        {
          'submitters' => [],
          'fields' => [
            {
              'name' => 'orphan-field',
              'type' => 'text',
              'submitter' => 'nonexistent_role',
              'position' => { 'page' => 0, 'x' => 0.10, 'y' => 0.20, 'w' => 0.30, 'h' => 0.04 }
            }
          ]
        }
      end

      it 'falls back to first existing submitter' do
        fields = described_class.call(template, config, documents)

        expect(fields.length).to eq(1)
        expect(fields.first['submitter_uuid']).to eq(template.submitters.first['uuid'])
      end
    end

    context 'with no attachment' do
      it 'returns empty array' do
        empty_template = create(:template, account: user.account, author: user, attachment_count: 0)

        config = { 'submitters' => [], 'fields' => [] }
        result = described_class.call(empty_template, config)

        expect(result).to eq([])
      end
    end

    context 'with multiple submitters' do
      let(:config) do
        {
          'submitters' => [{ 'name' => 'seller' }, { 'name' => 'buyer' }],
          'fields' => [
            {
              'name' => 'seller-sig',
              'type' => 'signature',
              'submitter' => 'seller',
              'position' => { 'page' => 0, 'x' => 0.1, 'y' => 0.5, 'w' => 0.2, 'h' => 0.05 }
            },
            {
              'name' => 'buyer-sig',
              'type' => 'signature',
              'submitter' => 'buyer',
              'position' => { 'page' => 0, 'x' => 0.5, 'y' => 0.5, 'w' => 0.2, 'h' => 0.05 }
            }
          ]
        }
      end

      it 'assigns correct submitter_uuid to each field' do
        fields = described_class.call(template, config, documents)

        seller = template.submitters.find { |s| s['name'].downcase == 'seller' }
        buyer = template.submitters.find { |s| s['name'].downcase == 'buyer' }

        expect(fields.length).to eq(2)
        expect(fields[0]['submitter_uuid']).to eq(seller['uuid'])
        expect(fields[1]['submitter_uuid']).to eq(buyer['uuid'])
      end
    end

    context 'with out-of-range page index' do
      let(:config) do
        {
          'submitters' => [{ 'name' => 'signer' }],
          'fields' => [
            {
              'name' => 'impossible-field',
              'type' => 'text',
              'submitter' => 'signer',
              'position' => { 'page' => 999, 'x' => 0.1, 'y' => 0.2, 'w' => 0.3, 'h' => 0.04 }
            }
          ]
        }
      end

      it 'skips fields with invalid page index' do
        fields = described_class.call(template, config, documents)

        expect(fields).to be_empty
      end
    end
  end

  describe '.resolve_page_index' do
    it 'returns page as-is for positive indices' do
      expect(described_class.resolve_page_index(0, 5)).to eq(0)
      expect(described_class.resolve_page_index(2, 5)).to eq(2)
    end

    it 'resolves negative indices from end' do
      expect(described_class.resolve_page_index(-1, 5)).to eq(4)
      expect(described_class.resolve_page_index(-2, 3)).to eq(1)
    end

    it 'returns nil for zero total pages' do
      expect(described_class.resolve_page_index(0, 0)).to be_nil
    end
  end

  describe '.clamp' do
    it 'clamps values between 0.0 and 1.0' do
      expect(described_class.clamp(-0.5)).to eq(0.0)
      expect(described_class.clamp(0.5)).to eq(0.5)
      expect(described_class.clamp(1.5)).to eq(1.0)
    end
  end

  describe '.clamp_dimension' do
    it 'enforces minimum dimension of 0.001' do
      expect(described_class.clamp_dimension(0.0)).to eq(0.001)
      expect(described_class.clamp_dimension(0.5)).to eq(0.5)
      expect(described_class.clamp_dimension(1.5)).to eq(1.0)
    end
  end
end
