# frozen_string_literal: true

# == Schema Information
#
# Table name: partnerships
#
#  id                      :bigint           not null, primary key
#  name                    :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  external_partnership_id :integer          not null
#
# Indexes
#
#  index_partnerships_on_external_partnership_id  (external_partnership_id) UNIQUE
#
describe Partnership do
  describe '#create_careerplug_webhook' do
    context 'when both env vars are present' do
      before do
        stub_const('ENV', ENV.to_h.merge(
                            'CAREERPLUG_WEBHOOK_URL' => 'https://example.com/webhook',
                            'CAREERPLUG_WEBHOOK_SECRET' => 'secret'
                          ))
      end

      it 'creates a webhook with the correct events on partnership creation' do
        partnership = create(:partnership)
        webhook = partnership.webhook_urls.last

        expect(webhook).to be_present
        expect(webhook.events).to match_array(%w[template.preferences_updated])
      end
    end

    context 'when env vars are missing' do
      before do
        stub_const('ENV', ENV.to_h.except('CAREERPLUG_WEBHOOK_URL', 'CAREERPLUG_WEBHOOK_SECRET'))
      end

      it 'does not create a webhook' do
        expect { create(:partnership) }.not_to change(WebhookUrl, :count)
      end
    end
  end

  describe 'validations' do
    it 'validates presence of external_partnership_id' do
      partnership = build(:partnership, external_partnership_id: nil)
      expect(partnership).not_to be_valid
      expect(partnership.errors[:external_partnership_id]).to include("can't be blank")
    end

    it 'validates uniqueness of external_partnership_id' do
      create(:partnership, external_partnership_id: 123)
      duplicate = build(:partnership, external_partnership_id: 123)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_partnership_id]).to include('has already been taken')
    end

    it 'validates presence of name' do
      partnership = build(:partnership, name: nil)
      expect(partnership).not_to be_valid
      expect(partnership.errors[:name]).to include("can't be blank")
    end
  end
end
