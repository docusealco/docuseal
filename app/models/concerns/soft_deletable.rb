# frozen_string_literal: true

# SoftDeletable Concern
# Purpose: Provides soft delete functionality for models
# Usage: include SoftDeletable in any model with a deleted_at column
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # Default scope to exclude soft-deleted records
    default_scope { where(deleted_at: nil) }

    # Scopes for querying soft-deleted records
    scope :active, -> { where(deleted_at: nil) }
    scope :archived, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
    scope :with_archived, -> { unscope(where: :deleted_at) }
  end

  # Soft delete the record by setting deleted_at timestamp
  # @return [Boolean] true if successful
  def soft_delete
    update(deleted_at: Time.current)
  end

  # Restore a soft-deleted record
  # @return [Boolean] true if successful
  def restore
    update(deleted_at: nil)
  end

  # Check if record is soft-deleted
  # @return [Boolean] true if deleted_at is present
  def deleted?
    deleted_at.present?
  end

  # Check if record is active (not soft-deleted)
  # @return [Boolean] true if deleted_at is nil
  def active?
    deleted_at.nil?
  end
end
