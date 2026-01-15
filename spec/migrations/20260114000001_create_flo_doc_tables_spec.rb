# frozen_string_literal: true

# Migration Spec: Create FloDoc Tables
# Purpose: Verify migration correctness, reversibility, and data integrity
# Coverage: Core migration functionality

require 'rails_helper'
require_relative '../../db/migrate/20260114000001_create_flo_doc_tables'

RSpec.describe CreateFloDocTables, type: :migration do
  let(:migration) { described_class.new }
  let(:conn) { ActiveRecord::Base.connection }

  # Helper to drop tables for testing
  def drop_tables_if_exist
    [:cohort_enrollments, :cohorts, :institutions].each do |table|
      conn.drop_table(table, if_exists: true)
    end
  end

  # Helper to drop FKs
  def drop_fks_if_exist
    [:cohorts, :cohort_enrollments].each do |table|
      conn.foreign_keys(table).each do |fk|
        conn.remove_foreign_key(table, name: fk.name)
      end
    end
  rescue => e
    # Ignore errors if FKs don't exist
  end

  # Ensure clean state before each test
  before do
    drop_fks_if_exist
    drop_tables_if_exist
  end

  after do
    drop_fks_if_exist
    drop_tables_if_exist
  end

  describe 'tables creation' do
    it 'creates institutions table' do
      expect { migration.change }.to change { conn.table_exists?(:institutions) }.from(false).to(true)
    end

    it 'creates cohorts table' do
      expect { migration.change }.to change { conn.table_exists?(:cohorts) }.from(false).to(true)
    end

    it 'creates cohort_enrollments table' do
      expect { migration.change }.to change { conn.table_exists?(:cohort_enrollments) }.from(false).to(true)
    end
  end

  describe 'schema validation' do
    before { migration.change }

    it 'has correct columns for institutions' do
      columns = conn.columns(:institutions).map(&:name)
      expect(columns).to include('name', 'email', 'contact_person', 'phone',
                                  'settings', 'created_at', 'updated_at', 'deleted_at')
    end

    it 'has correct columns for cohorts' do
      columns = conn.columns(:cohorts).map(&:name)
      expect(columns).to include('institution_id', 'template_id', 'name', 'program_type',
                                  'sponsor_email', 'required_student_uploads', 'cohort_metadata',
                                  'status', 'tp_signed_at', 'students_completed_at',
                                  'sponsor_completed_at', 'finalized_at', 'created_at',
                                  'updated_at', 'deleted_at')
    end

    it 'has correct columns for cohort_enrollments' do
      columns = conn.columns(:cohort_enrollments).map(&:name)
      expect(columns).to include('cohort_id', 'submission_id', 'student_email',
                                  'student_name', 'student_surname', 'student_id',
                                  'status', 'role', 'uploaded_documents', 'values',
                                  'completed_at', 'created_at', 'updated_at', 'deleted_at')
    end
  end

  describe 'column types and constraints' do
    before { migration.change }

    it 'has JSONB columns for flexible data' do
      # Institutions settings
      settings_column = conn.columns(:institutions).find { |c| c.name == 'settings' }
      expect(settings_column.type).to eq(:jsonb)

      # Cohorts required_student_uploads and metadata
      uploads_column = conn.columns(:cohorts).find { |c| c.name == 'required_student_uploads' }
      expect(uploads_column.type).to eq(:jsonb)
      metadata_column = conn.columns(:cohorts).find { |c| c.name == 'cohort_metadata' }
      expect(metadata_column.type).to eq(:jsonb)

      # CohortEnrollments uploaded_documents and values
      docs_column = conn.columns(:cohort_enrollments).find { |c| c.name == 'uploaded_documents' }
      expect(docs_column.type).to eq(:jsonb)
      values_column = conn.columns(:cohort_enrollments).find { |c| c.name == 'values' }
      expect(values_column.type).to eq(:jsonb)
    end

    it 'has NOT NULL constraints on required fields' do
      # Institutions
      name_column = conn.columns(:institutions).find { |c| c.name == 'name' }
      expect(name_column.null).to be false
      email_column = conn.columns(:institutions).find { |c| c.name == 'email' }
      expect(email_column.null).to be false

      # Cohorts
      institution_id_column = conn.columns(:cohorts).find { |c| c.name == 'institution_id' }
      expect(institution_id_column.null).to be false
      template_id_column = conn.columns(:cohorts).find { |c| c.name == 'template_id' }
      expect(template_id_column.null).to be false
      name_column = conn.columns(:cohorts).find { |c| c.name == 'name' }
      expect(name_column.null).to be false
      program_type_column = conn.columns(:cohorts).find { |c| c.name == 'program_type' }
      expect(program_type_column.null).to be false
      sponsor_email_column = conn.columns(:cohorts).find { |c| c.name == 'sponsor_email' }
      expect(sponsor_email_column.null).to be false

      # CohortEnrollments
      cohort_id_column = conn.columns(:cohort_enrollments).find { |c| c.name == 'cohort_id' }
      expect(cohort_id_column.null).to be false
      submission_id_column = conn.columns(:cohort_enrollments).find { |c| c.name == 'submission_id' }
      expect(submission_id_column.null).to be false
      student_email_column = conn.columns(:cohort_enrollments).find { |c| c.name == 'student_email' }
      expect(student_email_column.null).to be false
    end

    it 'has default values for status fields' do
      # Cohorts status
      cohort_status_column = conn.columns(:cohorts).find { |c| c.name == 'status' }
      expect(cohort_status_column.default).to eq('draft')

      # CohortEnrollments status and role
      enrollment_status_column = conn.columns(:cohort_enrollments).find { |c| c.name == 'status' }
      expect(enrollment_status_column.default).to eq('waiting')
      role_column = conn.columns(:cohort_enrollments).find { |c| c.name == 'role' }
      expect(role_column.default).to eq('student')
    end
  end

  describe 'indexes' do
    before { migration.change }

    it 'creates correct indexes on cohorts' do
      expect(conn.index_exists?(:cohorts, [:institution_id, :status])).to be true
      expect(conn.index_exists?(:cohorts, :template_id)).to be true
      expect(conn.index_exists?(:cohorts, :sponsor_email)).to be true
    end

    it 'creates correct indexes on cohort_enrollments' do
      expect(conn.index_exists?(:cohort_enrollments, [:cohort_id, :status])).to be true
      expect(conn.index_exists?(:cohort_enrollments, [:cohort_id, :student_email], unique: true)).to be true
      expect(conn.index_exists?(:cohort_enrollments, [:submission_id], unique: true)).to be true
    end
  end

  describe 'foreign keys' do
    before { migration.change }

    it 'creates foreign keys for cohorts' do
      expect(conn.foreign_key_exists?(:cohorts, :institutions)).to be true
      expect(conn.foreign_key_exists?(:cohorts, :templates)).to be true
    end

    it 'creates foreign keys for cohort_enrollments' do
      expect(conn.foreign_key_exists?(:cohort_enrollments, :cohorts)).to be true
      expect(conn.foreign_key_exists?(:cohort_enrollments, :submissions)).to be true
    end
  end

  describe 'reversibility' do
    # Reversibility tests need clean state - no before hook
    it 'is reversible' do
      # Ensure clean state
      drop_fks_if_exist
      drop_tables_if_exist

      # Tables should not exist before running migration
      expect(conn.table_exists?(:institutions)).to be false

      expect { migration.change }.to_not raise_error
      migration.down

      expect(conn.table_exists?(:institutions)).to be false
      expect(conn.table_exists?(:cohorts)).to be false
      expect(conn.table_exists?(:cohort_enrollments)).to be false
    end

    it 'removes indexes on rollback' do
      # Ensure clean state
      drop_fks_if_exist
      drop_tables_if_exist

      migration.change
      migration.down

      expect(conn.index_exists?(:cohorts, [:institution_id, :status])).to be false
      expect(conn.index_exists?(:cohort_enrollments, [:cohort_id, :student_email], unique: true)).to be false
    end

    it 'removes foreign keys on rollback' do
      # Ensure clean state
      drop_fks_if_exist
      drop_tables_if_exist

      migration.change
      migration.down

      expect(conn.foreign_key_exists?(:cohorts, :institutions)).to be false
      expect(conn.foreign_key_exists?(:cohort_enrollments, :submissions)).to be false
    end
  end

  describe 'data integrity constraints' do
    before { migration.change }

    it 'enforces NOT NULL via database constraints' do
      # Institutions - name
      expect {
        conn.execute("INSERT INTO institutions (email, created_at, updated_at) VALUES ('test@example.com', NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid)

      # Institutions - email
      expect {
        conn.execute("INSERT INTO institutions (name, created_at, updated_at) VALUES ('Test', NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid)

      # Cohorts - name (without required fields)
      expect {
        conn.execute("INSERT INTO cohorts (institution_id, template_id, program_type, sponsor_email, created_at, updated_at) VALUES (1, 1, 'learnership', 'test@example.com', NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid)

      # CohortEnrollments - student_email
      expect {
        conn.execute("INSERT INTO cohort_enrollments (cohort_id, submission_id, created_at, updated_at) VALUES (1, 1, NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'prevents orphaned records via foreign keys' do
      # Try to create cohort with non-existent institution
      expect {
        conn.execute("INSERT INTO cohorts (institution_id, template_id, name, program_type, sponsor_email, created_at, updated_at) VALUES (999999, 1, 'Test', 'learnership', 'test@example.com', NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid)

      # Try to create enrollment with non-existent cohort
      expect {
        conn.execute("INSERT INTO cohort_enrollments (cohort_id, submission_id, student_email, created_at, updated_at) VALUES (999999, 1, 'test@example.com', NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe 'default values and JSONB structure' do
    before { migration.change }

    it 'creates institutions with correct defaults' do
      conn.execute("INSERT INTO institutions (name, email, created_at, updated_at) VALUES ('Test', 'test@example.com', NOW(), NOW())")
      result = conn.select_one("SELECT settings, deleted_at FROM institutions WHERE name = 'Test'")
      # JSONB returns string in raw SQL, but empty object
      expect(result['settings']).to be_in([{}, '{}'])
      expect(result['deleted_at']).to be_nil
    end
  end
end
