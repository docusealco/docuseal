# frozen_string_literal: true

# == Schema Information
#
# Table name: account_groups
#
#  id                        :bigint           not null, primary key
#  name                      :string           not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  external_account_group_id :integer          not null
#
# Indexes
#
#  index_account_groups_on_external_account_group_id  (external_account_group_id) UNIQUE
#
describe AccountGroup do
  let(:account_group) { create(:account_group) }

  describe 'associations' do
    it 'has many accounts' do
      expect(account_group).to respond_to(:accounts)
    end
  end

  describe 'validations' do
    it 'validates presence of external_account_group_id' do
      account_group = build(:account_group, external_account_group_id: nil)
      expect(account_group).not_to be_valid
      expect(account_group.errors[:external_account_group_id]).to include("can't be blank")
    end

    it 'validates uniqueness of external_account_group_id' do
      create(:account_group, external_account_group_id: 123)
      duplicate = build(:account_group, external_account_group_id: 123)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_account_group_id]).to include('has already been taken')
    end

    it 'validates presence of name' do
      account_group = build(:account_group, name: nil)
      expect(account_group).not_to be_valid
      expect(account_group.errors[:name]).to include("can't be blank")
    end
  end

  describe 'when account group is destroyed' do
    it 'nullifies accounts account_group_id' do
      account = create(:account, account_group: account_group)

      account_group.destroy

      expect(account.reload.account_group).to be_nil
    end
  end
end
