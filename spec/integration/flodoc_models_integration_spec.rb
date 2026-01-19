# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FloDoc Models Integration', type: :integration do
  describe 'Integration with existing DocuSeal models' do
    describe 'Cohort and Template integration' do
      let(:template) { create(:template) }
      let(:institution) { create(:institution) }

      it 'can reference existing Template model' do
        cohort = create(:cohort, template: template, institution: institution)
        expect(cohort.template).to eq(template)
        expect(cohort.template_id).to eq(template.id)
      end

      it 'validates presence of template' do
        cohort = build(:cohort, template: nil, institution: institution)
        expect(cohort).not_to be_valid
      end

      it 'does not modify existing Template model' do
        expect(Template.column_names).not_to include('cohort_id')
      end
    end

    describe 'CohortEnrollment and Submission integration' do
      let(:submission) { create(:submission) }
      let(:cohort) { create(:cohort) }

      it 'can reference existing Submission model' do
        enrollment = create(:cohort_enrollment, submission: submission, cohort: cohort)
        expect(enrollment.submission).to eq(submission)
        expect(enrollment.submission_id).to eq(submission.id)
      end

      it 'validates presence of submission' do
        enrollment = build(:cohort_enrollment, submission: nil, cohort: cohort)
        expect(enrollment).not_to be_valid
      end

      it 'enforces unique submission_id constraint' do
        create(:cohort_enrollment, submission: submission, cohort: cohort)
        duplicate = build(:cohort_enrollment, submission: submission, cohort: cohort)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:submission_id]).to be_present
      end

      it 'does not modify existing Submission model' do
        expect(Submission.column_names).not_to include('cohort_enrollment_id')
      end
    end

    describe 'Cohort has_many submissions through cohort_enrollments' do
      let(:cohort) { create(:cohort) }
      let(:submission1) { create(:submission) }
      let(:submission2) { create(:submission) }

      before do
        create(:cohort_enrollment, cohort: cohort, submission: submission1)
        create(:cohort_enrollment, cohort: cohort, submission: submission2)
      end

      it 'can access submissions through cohort_enrollments' do
        expect(cohort.submissions).to include(submission1, submission2)
        expect(cohort.submissions.count).to eq(2)
      end
    end

    describe 'Institution has_many cohorts' do
      let(:institution) { create(:institution) }
      let!(:cohort1) { create(:cohort, institution: institution) }
      let!(:cohort2) { create(:cohort, institution: institution) }

      it 'can access cohorts through institution' do
        expect(institution.cohorts).to include(cohort1, cohort2)
        expect(institution.cohorts.count).to eq(2)
      end

      it 'destroys cohorts when institution is destroyed' do
        expect { institution.destroy }
          .to change(Cohort, :count).by(-2)
      end
    end

    describe 'Cohort has_many cohort_enrollments' do
      let(:cohort) { create(:cohort) }
      let!(:enrollment1) { create(:cohort_enrollment, cohort: cohort) }
      let!(:enrollment2) { create(:cohort_enrollment, cohort: cohort) }

      it 'can access enrollments through cohort' do
        expect(cohort.cohort_enrollments).to include(enrollment1, enrollment2)
        expect(cohort.cohort_enrollments.count).to eq(2)
      end

      it 'destroys enrollments when cohort is destroyed' do
        expect { cohort.destroy }
          .to change(CohortEnrollment, :count).by(-2)
      end
    end
  end

  describe 'Query performance' do
    let(:institution) { create(:institution) }
    let(:template) { create(:template) }

    before do
      # Create test data
      5.times do
        cohort = create(:cohort, institution: institution, template: template)
        10.times do
          submission = create(:submission)
          create(:cohort_enrollment, cohort: cohort, submission: submission)
        end
      end
    end

    it 'eager loads associations to avoid N+1 queries' do
      # Without eager loading - N+1 queries
      expect do
        Cohort.all.each do |cohort|
          cohort.institution.name
          cohort.template.name
        end
      end.to make_database_queries(count: 11..15)

      # With eager loading - fewer queries
      expect do
        Cohort.includes(:institution, :template).each do |cohort|
          cohort.institution.name
          cohort.template.name
        end
      end.to make_database_queries(count: 1..5)
    end

    it 'handles large datasets efficiently' do
      start_time = Time.current
      Cohort.includes(:institution, :template, :cohort_enrollments).all.to_a
      query_time = Time.current - start_time

      # Query should complete in under 1 second for 50 enrollments
      expect(query_time).to be < 1.0
    end
  end

  describe 'Data integrity' do
    it 'maintains referential integrity with foreign keys' do
      institution = create(:institution)
      cohort = create(:cohort, institution: institution)

      # Cannot delete institution with cohorts (due to dependent: :destroy)
      expect { institution.destroy }.to change(Cohort, :count).by(-1)
    end

    it 'prevents orphaned cohort_enrollments' do
      cohort = create(:cohort)
      enrollment = create(:cohort_enrollment, cohort: cohort)

      # Deleting cohort should delete enrollments
      expect { cohort.destroy }.to change(CohortEnrollment, :count).by(-1)
    end

    it 'validates foreign key constraints' do
      # Attempting to create cohort with non-existent institution should fail
      expect do
        Cohort.create!(
          institution_id: 999_999,
          template_id: create(:template).id,
          name: 'Test',
          program_type: 'learnership',
          sponsor_email: 'test@example.com'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
