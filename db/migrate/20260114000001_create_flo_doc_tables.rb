# frozen_string_literal: true

# Migration: Create FloDoc Tables
# Purpose: Add database schema for 3-portal cohort management system
# Tables: institutions, cohorts, cohort_enrollments
# Integration: References existing templates and submissions tables
# Risk: MEDIUM-HIGH - Foreign keys to existing tables require careful validation

class CreateFloDocTables < ActiveRecord::Migration[7.0]
  def change
    # Wrap in transaction for atomicity and rollback support
    transaction do
      # Table: institutions
      # Purpose: Single training institution per deployment (not multi-tenant)
      # FR1: Single institution record per deployment
      create_table :institutions do |t|
        t.string :name, null: false
        t.string :email, null: false
        t.string :contact_person
        t.string :phone
        t.jsonb :settings, default: {}
        t.timestamps
        t.datetime :deleted_at # Soft delete for POPIA compliance
      end

      # Table: cohorts
      # Purpose: Training program cohorts (wraps DocuSeal templates)
      # FR2: 5-step cohort creation workflow
      # FR3: State tracking through workflow phases
      create_table :cohorts do |t|
        t.references :institution, null: false # FK added separately for explicit control
        t.references :template, null: false, index: false # References existing DocuSeal table, index added separately
        t.string :name, null: false
        t.string :program_type, null: false # learnership/internship/candidacy
        t.string :sponsor_email, null: false # Single email rule
        t.jsonb :required_student_uploads, default: [] # ID, Matric, Qualifications
        t.jsonb :cohort_metadata, default: {} # Flexible metadata
        t.string :status, default: 'draft' # draft → active → completed
        t.datetime :tp_signed_at # TP signing phase completion
        t.datetime :students_completed_at # Student enrollment completion
        t.datetime :sponsor_completed_at # Sponsor review completion
        t.datetime :finalized_at # TP review and finalization
        t.timestamps
        t.datetime :deleted_at # Soft delete
      end

      # Table: cohort_enrollments
      # Purpose: Student enrollments in cohorts (wraps DocuSeal submissions)
      # FR4: Ad-hoc student enrollment without account creation
      # FR5: Single email rule for sponsor
      create_table :cohort_enrollments do |t|
        t.references :cohort, null: false # FK added separately for explicit control
        t.references :submission, null: false, index: false # References existing DocuSeal table, unique index added separately
        t.string :student_email, null: false
        t.string :student_name
        t.string :student_surname
        t.string :student_id
        t.string :status, default: 'waiting' # waiting → in_progress → complete
        t.string :role, default: 'student' # student or sponsor
        t.jsonb :uploaded_documents, default: {} # Track required uploads
        t.jsonb :values, default: {} # Form field values
        t.datetime :completed_at
        t.timestamps
        t.datetime :deleted_at # Soft delete
      end

      # Indexes for performance
      # FR3: State tracking requires efficient queries by status
      add_index :cohorts, %i[institution_id status]
      add_index :cohorts, :template_id
      add_index :cohorts, :sponsor_email

      add_index :cohort_enrollments, %i[cohort_id status]
      add_index :cohort_enrollments, %i[cohort_id student_email], unique: true
      add_index :cohort_enrollments, [:submission_id], unique: true

      # Foreign key constraints
      # Risk mitigation: T-01, I-01, I-02
      # Prevents orphaned records and ensures referential integrity
      add_foreign_key :cohorts, :institutions
      add_foreign_key :cohorts, :templates
      add_foreign_key :cohort_enrollments, :cohorts
      add_foreign_key :cohort_enrollments, :submissions
    end
  end
end
