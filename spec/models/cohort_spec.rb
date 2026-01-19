# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cohort, type: :model do
  describe 'concerns' do
    it 'includes SoftDeletable' do
      expect(Cohort.ancestors).to include(SoftDeletable)
    end

    it 'includes AASM' do
      expect(Cohort.ancestors).to include(AASM)
    end
  end

  describe 'associations' do
    it { should belong_to(:institution) }
    it { should belong_to(:template) }
    it { should have_many(:cohort_enrollments).dependent(:destroy) }
    it { should have_many(:submissions).through(:cohort_enrollments) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:program_type) }
    it { should validate_presence_of(:sponsor_email) }
    it { should validate_inclusion_of(:program_type).in_array(%w[learnership internship candidacy]) }
    it { should validate_inclusion_of(:status).in_array(%w[draft active completed]) }

    it 'validates sponsor email format' do
      cohort = build(:cohort, sponsor_email: 'invalid-email')
      expect(cohort).not_to be_valid
      expect(cohort.errors[:sponsor_email]).to be_present
    end

    it 'accepts valid email format' do
      cohort = build(:cohort, sponsor_email: 'sponsor@example.com')
      expect(cohort).to be_valid
    end
  end

  describe 'strip_attributes' do
    it 'strips whitespace from name' do
      cohort = create(:cohort, name: '  Test Cohort  ')
      expect(cohort.name).to eq('Test Cohort')
    end

    it 'strips whitespace from program_type' do
      cohort = create(:cohort, program_type: '  learnership  ')
      expect(cohort.program_type).to eq('learnership')
    end

    it 'strips whitespace from sponsor_email' do
      cohort = create(:cohort, sponsor_email: '  sponsor@example.com  ')
      expect(cohort.sponsor_email).to eq('sponsor@example.com')
    end
  end

  describe 'scopes' do
    let!(:draft_cohort) { create(:cohort, status: 'draft') }
    let!(:active_cohort) { create(:cohort, status: 'active') }
    let!(:completed_cohort) { create(:cohort, status: 'completed') }
    let!(:deleted_cohort) { create(:cohort, deleted_at: Time.current) }

    describe '.draft' do
      it 'returns only draft cohorts' do
        expect(Cohort.draft).to include(draft_cohort)
        expect(Cohort.draft).not_to include(active_cohort, completed_cohort)
      end
    end

    describe '.active_status' do
      it 'returns only active cohorts' do
        expect(Cohort.active_status).to include(active_cohort)
        expect(Cohort.active_status).not_to include(draft_cohort, completed_cohort)
      end
    end

    describe '.completed' do
      it 'returns only completed cohorts' do
        expect(Cohort.completed).to include(completed_cohort)
        expect(Cohort.completed).not_to include(draft_cohort, active_cohort)
      end
    end

    describe '.ready_for_sponsor' do
      let!(:ready_cohort) do
        create(:cohort, status: 'active', students_completed_at: Time.current)
      end

      it 'returns active cohorts with students_completed_at set' do
        expect(Cohort.ready_for_sponsor).to include(ready_cohort)
        expect(Cohort.ready_for_sponsor).not_to include(active_cohort)
      end
    end

    describe '.active (from SoftDeletable)' do
      it 'excludes soft-deleted cohorts' do
        expect(Cohort.active).not_to include(deleted_cohort)
      end
    end
  end

  describe 'state machine' do
    let(:cohort) { create(:cohort, status: 'draft') }

    describe 'initial state' do
      it 'starts in draft state' do
        expect(cohort.draft?).to be true
      end
    end

    describe '#activate event' do
      it 'transitions from draft to active' do
        expect { cohort.activate! }
          .to change(cohort, :status).from('draft').to('active')
      end

      it 'sets tp_signed_at timestamp' do
        expect { cohort.activate! }
          .to change(cohort, :tp_signed_at).from(nil)
      end

      it 'cannot transition from completed to active' do
        cohort.update!(status: 'completed')
        expect { cohort.activate! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe '#complete event' do
      before { cohort.update!(status: 'active') }

      it 'transitions from active to completed' do
        expect { cohort.complete! }
          .to change(cohort, :status).from('active').to('completed')
      end

      it 'sets finalized_at timestamp' do
        expect { cohort.complete! }
          .to change(cohort, :finalized_at).from(nil)
      end

      it 'cannot transition from draft to completed' do
        cohort.update!(status: 'draft')
        expect { cohort.complete! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe 'state predicates' do
      it 'provides draft? predicate' do
        cohort.update!(status: 'draft')
        expect(cohort.draft?).to be true
        expect(cohort.active?).to be false
        expect(cohort.completed?).to be false
      end

      it 'provides active? predicate' do
        cohort.update!(status: 'active')
        expect(cohort.active?).to be true
        expect(cohort.draft?).to be false
        expect(cohort.completed?).to be false
      end

      it 'provides completed? predicate' do
        cohort.update!(status: 'completed')
        expect(cohort.completed?).to be true
        expect(cohort.draft?).to be false
        expect(cohort.active?).to be false
      end
    end
  end

  describe '#all_students_completed?' do
    let(:cohort) { create(:cohort) }

    context 'when no student enrollments exist' do
      it 'returns false' do
        expect(cohort.all_students_completed?).to be false
      end
    end

    context 'when all student enrollments are completed' do
      before do
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'complete')
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'complete')
      end

      it 'returns true' do
        expect(cohort.all_students_completed?).to be true
      end
    end

    context 'when some student enrollments are not completed' do
      before do
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'complete')
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'waiting')
      end

      it 'returns false' do
        expect(cohort.all_students_completed?).to be false
      end
    end

    context 'when sponsor enrollment exists' do
      before do
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'complete')
        create(:cohort_enrollment, cohort: cohort, role: 'sponsor', status: 'waiting')
      end

      it 'only checks student enrollments' do
        expect(cohort.all_students_completed?).to be true
      end
    end
  end

  describe '#sponsor_access_ready?' do
    let(:cohort) { create(:cohort, status: 'active', tp_signed_at: Time.current) }

    context 'when all conditions are met' do
      before do
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'complete')
      end

      it 'returns true' do
        expect(cohort.sponsor_access_ready?).to be true
      end
    end

    context 'when cohort is not active' do
      before do
        cohort.update!(status: 'draft')
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'complete')
      end

      it 'returns false' do
        expect(cohort.sponsor_access_ready?).to be false
      end
    end

    context 'when tp_signed_at is not set' do
      before do
        cohort.update!(tp_signed_at: nil)
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'complete')
      end

      it 'returns false' do
        expect(cohort.sponsor_access_ready?).to be false
      end
    end

    context 'when not all students are completed' do
      before do
        create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'waiting')
      end

      it 'returns false' do
        expect(cohort.sponsor_access_ready?).to be false
      end
    end
  end

  describe '#tp_can_sign?' do
    it 'returns true when cohort is in draft state' do
      cohort = create(:cohort, status: 'draft')
      expect(cohort.tp_can_sign?).to be true
    end

    it 'returns false when cohort is active' do
      cohort = create(:cohort, status: 'active')
      expect(cohort.tp_can_sign?).to be false
    end

    it 'returns false when cohort is completed' do
      cohort = create(:cohort, status: 'completed')
      expect(cohort.tp_can_sign?).to be false
    end
  end

  describe 'soft delete functionality' do
    let(:cohort) { create(:cohort) }

    it 'soft deletes the record' do
      expect { cohort.soft_delete }
        .to change { cohort.reload.deleted_at }.from(nil)
    end

    it 'excludes soft-deleted records from default scope' do
      cohort.soft_delete
      expect(Cohort.all).not_to include(cohort)
    end

    it 'restores soft-deleted records' do
      cohort.soft_delete
      expect { cohort.restore }
        .to change { cohort.reload.deleted_at }.to(nil)
    end
  end
end
