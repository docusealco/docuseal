# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SoftDeletable, type: :model do
  # Create a test model that includes the concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'institutions'
      include SoftDeletable
    end
  end

  let(:record) { test_class.create!(name: 'Test', email: 'test@example.com') }

  describe 'scopes' do
    let!(:active_record) { test_class.create!(name: 'Active', email: 'active@example.com') }
    let!(:deleted_record) do
      test_class.create!(name: 'Deleted', email: 'deleted@example.com', deleted_at: Time.current)
    end

    describe '.active' do
      it 'returns only non-deleted records' do
        expect(test_class.active).to include(active_record)
        expect(test_class.active).not_to include(deleted_record)
      end
    end

    describe '.archived' do
      it 'returns only deleted records' do
        expect(test_class.archived).to include(deleted_record)
        expect(test_class.archived).not_to include(active_record)
      end
    end

    describe '.with_archived' do
      it 'returns all records including deleted' do
        expect(test_class.with_archived).to include(active_record, deleted_record)
      end
    end

    describe 'default scope' do
      it 'excludes soft-deleted records by default' do
        expect(test_class.all).to include(active_record)
        expect(test_class.all).not_to include(deleted_record)
      end
    end
  end

  describe '#soft_delete' do
    it 'sets deleted_at timestamp' do
      expect { record.soft_delete }
        .to change { record.reload.deleted_at }.from(nil)
    end

    it 'returns true on success' do
      expect(record.soft_delete).to be true
    end

    it 'excludes record from default scope after deletion' do
      record.soft_delete
      expect(test_class.all).not_to include(record)
    end
  end

  describe '#restore' do
    before { record.update!(deleted_at: Time.current) }

    it 'clears deleted_at timestamp' do
      expect { record.restore }
        .to change { record.reload.deleted_at }.to(nil)
    end

    it 'returns true on success' do
      expect(record.restore).to be true
    end

    it 'includes record in default scope after restoration' do
      record.restore
      expect(test_class.all).to include(record)
    end
  end

  describe '#deleted?' do
    it 'returns false when deleted_at is nil' do
      expect(record.deleted?).to be false
    end

    it 'returns true when deleted_at is present' do
      record.update!(deleted_at: Time.current)
      expect(record.deleted?).to be true
    end
  end

  describe '#active?' do
    it 'returns true when deleted_at is nil' do
      expect(record.active?).to be true
    end

    it 'returns false when deleted_at is present' do
      record.update!(deleted_at: Time.current)
      expect(record.active?).to be false
    end
  end
end
