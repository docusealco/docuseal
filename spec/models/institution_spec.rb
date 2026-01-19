# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Institution, type: :model do
  describe 'concerns' do
    it 'includes SoftDeletable' do
      expect(Institution.ancestors).to include(SoftDeletable)
    end
  end

  describe 'associations' do
    it { should have_many(:cohorts).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(255) }

    it 'validates email format' do
      institution = build(:institution, email: 'invalid-email')
      expect(institution).not_to be_valid
      expect(institution.errors[:email]).to be_present
    end

    it 'accepts valid email format' do
      institution = build(:institution, email: 'valid@example.com')
      expect(institution).to be_valid
    end
  end

  describe 'strip_attributes' do
    it 'strips whitespace from name' do
      institution = create(:institution, name: '  Test Institution  ')
      expect(institution.name).to eq('Test Institution')
    end

    it 'strips whitespace from email' do
      institution = create(:institution, email: '  test@example.com  ')
      expect(institution.email).to eq('test@example.com')
    end

    it 'strips whitespace from contact_person' do
      institution = create(:institution, contact_person: '  John Doe  ')
      expect(institution.contact_person).to eq('John Doe')
    end

    it 'strips whitespace from phone' do
      institution = create(:institution, phone: '  +27123456789  ')
      expect(institution.phone).to eq('+27123456789')
    end
  end

  describe 'scopes' do
    let!(:active_institution) { create(:institution) }
    let!(:deleted_institution) { create(:institution, deleted_at: Time.current) }

    describe '.active' do
      it 'returns only active institutions' do
        expect(Institution.active).to include(active_institution)
        expect(Institution.active).not_to include(deleted_institution)
      end
    end

    describe '.archived' do
      it 'returns only soft-deleted institutions' do
        expect(Institution.archived).to include(deleted_institution)
        expect(Institution.archived).not_to include(active_institution)
      end
    end
  end

  describe '.current' do
    context 'when institutions exist' do
      let!(:first_institution) { create(:institution, name: 'First Institution') }
      let!(:second_institution) { create(:institution, name: 'Second Institution') }

      it 'returns the first institution' do
        expect(Institution.current).to eq(first_institution)
      end
    end

    context 'when no institutions exist' do
      it 'returns nil' do
        expect(Institution.current).to be_nil
      end
    end
  end

  describe '#settings_with_defaults' do
    let(:institution) { create(:institution, settings: custom_settings) }

    context 'with empty settings' do
      let(:custom_settings) { {} }

      it 'returns default settings' do
        settings = institution.settings_with_defaults
        expect(settings[:allow_student_enrollment]).to be true
        expect(settings[:require_verification]).to be true
        expect(settings[:auto_finalize]).to be false
        expect(settings[:email_notifications]).to be true
      end
    end

    context 'with custom settings' do
      let(:custom_settings) do
        {
          'allow_student_enrollment' => false,
          'custom_setting' => 'custom_value'
        }
      end

      it 'merges custom settings with defaults' do
        settings = institution.settings_with_defaults
        expect(settings[:allow_student_enrollment]).to be false
        expect(settings[:require_verification]).to be true
        expect(settings[:custom_setting]).to eq('custom_value')
      end
    end

    it 'returns HashWithIndifferentAccess' do
      expect(institution.settings_with_defaults).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end
  end

  describe 'soft delete functionality' do
    let(:institution) { create(:institution) }

    it 'soft deletes the record' do
      expect { institution.soft_delete }
        .to change { institution.reload.deleted_at }.from(nil)
    end

    it 'excludes soft-deleted records from default scope' do
      institution.soft_delete
      expect(Institution.all).not_to include(institution)
    end

    it 'restores soft-deleted records' do
      institution.soft_delete
      expect { institution.restore }
        .to change { institution.reload.deleted_at }.to(nil)
    end

    it 'checks if record is deleted' do
      expect(institution.deleted?).to be false
      institution.soft_delete
      expect(institution.deleted?).to be true
    end

    it 'checks if record is active' do
      expect(institution.active?).to be true
      institution.soft_delete
      expect(institution.active?).to be false
    end
  end
end
