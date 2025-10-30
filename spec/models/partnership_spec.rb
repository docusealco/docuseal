# frozen_string_literal: true

# == Schema Information
#
# Table name: partnerships
#
#  id                      :bigint           not null, primary key
#  name                    :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  external_partnership_id :string           not null
#
# Indexes
#
#  index_partnerships_on_external_partnership_id  (external_partnership_id) UNIQUE
#
describe Partnership do
  let(:partnership) { create(:partnership) }

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
