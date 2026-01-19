# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortEnrollment, type: :model do
  describe 'concerns' do
    it 'includes SoftDeletable' do
      expect(CohortEnrollment.ancestors).to include(SoftDeletable)
    end
  end

  describe 'associations' do
    it { should belong_to(:cohort) }
    it { should belong_to(:submission) }
  end

  describe 'validations' do
    subject { build(:cohort_enrollment) }

    it { should validate_presence_of(:student_email) }
    it { should validate_uniqueness_of(:submission_id) }
    it { should validate_inclusion_of(:status).in_array(%w[waiting in_progress complete]) }
    it { should validate_inclusion_of(:role).in_array(%w[student sponsor]) }

    it 'validates student email format' do
      enrollment = build(:cohort_enrollment, student_email: 'invalid-email')
      expect(enrollment).not_to be_valid
      expect(enrollment.errors[:student_email]).to be_present
    end

    it 'accepts valid email format' do
      enrollment = build(:cohort_enrollment, student_email: 'student@example.com')
      expect(enrollment).to be_valid
    end

    describe 'uniqueness validations' do
      let(:cohort) { create(:cohort) }
      let!(:existing_enrollment) do
        create(:cohort_enrollment, cohort: cohort, student_email: 'student@example.com')
      end

      it 'validates uniqueness of student_email scoped to cohort_id' do
        duplicate = build(:cohort_enrollment, cohort: cohort, student_email: 'student@example.com')
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:student_email]).to be_present
      end

      it 'allows same email in different cohorts' do
        other_cohort = create(:cohort)
        enrollment = build(:cohort_enrollment, cohort: other_cohort, student_email: 'student@example.com')
        expect(enrollment).to be_valid
      end

      it 'validates uniqueness case-insensitively' do
        duplicate = build(:cohort_enrollment, cohort: cohort, student_email: 'STUDENT@example.com')
        expect(duplicate).not_to be_valid
      end
    end
  end

  describe 'strip_attributes' do
    it 'strips whitespace from student_email' do
      enrollment = create(:cohort_enrollment, student_email: '  student@example.com  ')
      expect(enrollment.student_email).to eq('student@example.com')
    end

    it 'strips whitespace from student_name' do
      enrollment = create(:cohort_enrollment, student_name: '  John  ')
      expect(enrollment.student_name).to eq('John')
    end

    it 'strips whitespace from student_surname' do
      enrollment = create(:cohort_enrollment, student_surname: '  Doe  ')
      expect(enrollment.student_surname).to eq('Doe')
    end

    it 'strips whitespace from student_id' do
      enrollment = create(:cohort_enrollment, student_id: '  12345  ')
      expect(enrollment.student_id).to eq('12345')
    end

    it 'strips whitespace from role' do
      enrollment = create(:cohort_enrollment, role: '  student  ')
      expect(enrollment.role).to eq('student')
    end
  end

  describe 'scopes' do
    let(:cohort) { create(:cohort) }
    let!(:student_waiting) { create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'waiting') }
    let!(:student_in_progress) { create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'in_progress') }
    let!(:student_complete) { create(:cohort_enrollment, cohort: cohort, role: 'student', status: 'complete') }
    let!(:sponsor_enrollment) { create(:cohort_enrollment, cohort: cohort, role: 'sponsor', status: 'waiting') }
    let!(:deleted_enrollment) { create(:cohort_enrollment, cohort: cohort, deleted_at: Time.current) }

    describe '.students' do
      it 'returns only student enrollments' do
        expect(CohortEnrollment.students).to include(student_waiting, student_in_progress, student_complete)
        expect(CohortEnrollment.students).not_to include(sponsor_enrollment)
      end
    end

    describe '.sponsor' do
      it 'returns only sponsor enrollments' do
        expect(CohortEnrollment.sponsor).to include(sponsor_enrollment)
        expect(CohortEnrollment.sponsor).not_to include(student_waiting)
      end
    end

    describe '.waiting' do
      it 'returns only waiting enrollments' do
        expect(CohortEnrollment.waiting).to include(student_waiting, sponsor_enrollment)
        expect(CohortEnrollment.waiting).not_to include(student_in_progress, student_complete)
      end
    end

    describe '.in_progress' do
      it 'returns only in_progress enrollments' do
        expect(CohortEnrollment.in_progress).to include(student_in_progress)
        expect(CohortEnrollment.in_progress).not_to include(student_waiting, student_complete)
      end
    end

    describe '.complete' do
      it 'returns only complete enrollments' do
        expect(CohortEnrollment.complete).to include(student_complete)
        expect(CohortEnrollment.complete).not_to include(student_waiting, student_in_progress)
      end
    end

    describe '.active (from SoftDeletable)' do
      it 'excludes soft-deleted enrollments' do
        expect(CohortEnrollment.active).not_to include(deleted_enrollment)
      end
    end
  end

  describe '#complete!' do
    let(:enrollment) { create(:cohort_enrollment, status: 'waiting', completed_at: nil) }

    it 'changes status to complete' do
      expect { enrollment.complete! }
        .to change(enrollment, :status).from('waiting').to('complete')
    end

    it 'sets completed_at timestamp' do
      expect { enrollment.complete! }
        .to change(enrollment, :completed_at).from(nil)
    end

    it 'returns true on success' do
      expect(enrollment.complete!).to be true
    end
  end

  describe '#mark_in_progress!' do
    let(:enrollment) { create(:cohort_enrollment, status: 'waiting') }

    it 'changes status to in_progress' do
      expect { enrollment.mark_in_progress! }
        .to change(enrollment, :status).from('waiting').to('in_progress')
    end

    it 'returns true on success' do
      expect(enrollment.mark_in_progress!).to be true
    end
  end

  describe '#waiting?' do
    it 'returns true when status is waiting' do
      enrollment = create(:cohort_enrollment, status: 'waiting')
      expect(enrollment.waiting?).to be true
    end

    it 'returns false when status is not waiting' do
      enrollment = create(:cohort_enrollment, status: 'complete')
      expect(enrollment.waiting?).to be false
    end
  end

  describe '#completed?' do
    it 'returns true when status is complete' do
      enrollment = create(:cohort_enrollment, status: 'complete')
      expect(enrollment.completed?).to be true
    end

    it 'returns false when status is not complete' do
      enrollment = create(:cohort_enrollment, status: 'waiting')
      expect(enrollment.completed?).to be false
    end
  end

  describe 'soft delete functionality' do
    let(:enrollment) { create(:cohort_enrollment) }

    it 'soft deletes the record' do
      expect { enrollment.soft_delete }
        .to change { enrollment.reload.deleted_at }.from(nil)
    end

    it 'excludes soft-deleted records from default scope' do
      enrollment.soft_delete
      expect(CohortEnrollment.all).not_to include(enrollment)
    end

    it 'restores soft-deleted records' do
      enrollment.soft_delete
      expect { enrollment.restore }
        .to change { enrollment.reload.deleted_at }.to(nil)
    end
  end

  describe 'integration with existing models' do
    it 'can reference existing Submission model' do
      submission = create(:submission)
      enrollment = create(:cohort_enrollment, submission: submission)
      expect(enrollment.submission).to eq(submission)
    end

    it 'belongs to a cohort' do
      cohort = create(:cohort)
      enrollment = create(:cohort_enrollment, cohort: cohort)
      expect(enrollment.cohort).to eq(cohort)
    end
  end
end
