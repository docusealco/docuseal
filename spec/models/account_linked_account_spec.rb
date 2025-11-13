# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountLinkedAccount, type: :model do
  describe 'associations' do
    it 'has account association' do
      expect(described_class.reflect_on_association(:account).macro).to eq(:belongs_to)
    end

    it 'has linked_account association with correct class_name' do
      association = described_class.reflect_on_association(:linked_account)
      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq('Account')
    end

    context 'when creating with associated records' do
      let(:account) { create(:account, name: 'Primary Account') }
      let(:linked_account_record) { create(:account, name: 'Linked Account') }
      let(:account_linked) { create(:account_linked_account, account: account, linked_account: linked_account_record) }

      it 'properly associates with account' do
        expect(account_linked.account).to eq(account)
        expect(account_linked.account.name).to eq('Primary Account')
        expect(account_linked.account_id).to eq(account.id)
      end

      it 'properly associates with linked_account' do
        expect(account_linked.linked_account).to eq(linked_account_record)
        expect(account_linked.linked_account.name).to eq('Linked Account')
        expect(account_linked.linked_account_id).to eq(linked_account_record.id)
      end
    end
  end

  describe 'attribute default' do
    context 'when account_type is not specified' do
      let(:linked_account) { create(:account_linked_account) }

      it "defaults account_type to 'testing'" do
        expect(linked_account.account_type).to eq('testing')
        expect(linked_account.testing?).to be true
      end
    end

    context 'when account_type is explicitly set to nil' do
      it 'raises not null constraint violation' do
        expect { create(:account_linked_account, account_type: nil) }
          .to raise_error(ActiveRecord::NotNullViolation)
      end
    end
  end

  describe 'database constraints' do
    context 'with uniqueness constraint' do
      let(:account) { create(:account) }

      it 'prevents duplicate account_id and linked_account_id combinations' do
        create(:account_linked_account, account: account, linked_account: account)
        duplicate = build(:account_linked_account, account: account, linked_account: account)

        expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'with foreign key constraints' do
      let(:invalid_account_linked) { build(:account_linked_account, account_id: 999_999, linked_account_id: 999_999) }

      it 'enforces account foreign key constraint with validation' do
        expect { invalid_account_linked.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'enforces foreign key constraint at database level' do
        expect { invalid_account_linked.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
      end
    end

    context 'with not null constraints' do
      let(:invalid_record) { described_class.new }

      it 'validates account presence' do
        expect(invalid_record).not_to be_valid
        expect(invalid_record.errors[:account]).to include('must exist')
      end

      it 'validates linked_account presence' do
        expect(invalid_record).not_to be_valid
        expect(invalid_record.errors[:linked_account]).to include('must exist')
      end

      it 'enforces account_type not null constraint at database level' do
        account = create(:account)
        expect do
          described_class.create!(account: account, linked_account: account, account_type: nil)
        end.to raise_error(ActiveRecord::NotNullViolation)
      end
    end
  end

  describe '#testing?' do
    context "when account_type is the default 'testing' value" do
      let(:linked_account) { create(:account_linked_account) }

      it 'returns true for default account_type' do
        expect(linked_account.testing?).to be true
        expect(linked_account.account_type).to eq('testing')
      end
    end

    context "when account_type is explicitly set to 'testing'" do
      let(:linked_account) { create(:account_linked_account, account_type: 'testing') }

      it "returns true when account_type is explicitly 'testing'" do
        expect(linked_account.testing?).to be true
        expect(linked_account.account_type).to eq('testing')
      end
    end

    context 'when account_type is set to a different value' do
      let(:linked_account) { create(:account_linked_account, account_type: 'production') }

      it "returns false when account_type is 'production'" do
        expect(linked_account.testing?).to be false
        expect(linked_account.account_type).to eq('production')
      end
    end

    context 'when account_type is case variation' do
      let(:linked_account) { create(:account_linked_account, account_type: 'TESTING') }

      it "returns false when account_type is uppercase 'TESTING'" do
        expect(linked_account.testing?).to be false
        expect(linked_account.account_type).to eq('TESTING')
      end

      it "returns false when account_type is lowercase 'testing' but with different casing" do
        linked_account = create(:account_linked_account, account_type: 'TeStInG')
        expect(linked_account.testing?).to be false
        expect(linked_account.account_type).to eq('TeStInG')
      end
    end

    context 'when testing multiple instances with different account_types' do
      let(:testing_account) { create(:account_linked_account, account_type: 'testing') }
      let(:production_account) { create(:account_linked_account, account_type: 'production') }
      let(:staging_account) { create(:account_linked_account, account_type: 'staging') }

      it 'correctly identifies testing versus non-testing accounts' do
        expect(testing_account.testing?).to be true
        expect(production_account.testing?).to be false
        expect(staging_account.testing?).to be false
      end

      it 'maintains correct account_type values after testing' do
        expect(testing_account.account_type).to eq('testing')
        expect(production_account.account_type).to eq('production')
        expect(staging_account.account_type).to eq('staging')
      end
    end
  end
end
