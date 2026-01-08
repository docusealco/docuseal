# frozen_string_literal: true

# FloDoc additions to User model
# This file contains the institution management methods that should be
# merged into app/models/user.rb

module UserFloDocAdditions
  extend ActiveSupport::Concern

  included do
    # Layer 2: Institution relationships
    has_many :account_accesses, dependent: :destroy
    has_many :institutions, through: :account_accesses
    has_many :managed_institutions, class_name: 'Institution', foreign_key: 'super_admin_id', dependent: :destroy
  end

  # CRITICAL METHODS: Layer 2 security - Institution access verification
  def can_access_institution?(institution)
    institutions.exists?(institution.id) || managed_institutions.exists?(institution.id)
  end

  # Role checking methods
  def cohort_super_admin?
    account_accesses.exists?(role: 'cohort_super_admin')
  end

  def cohort_admin?
    account_accesses.exists?(role: 'cohort_admin')
  end

  # Combined role check
  def any_cohort_admin?
    cohort_super_admin? || cohort_admin?
  end

  # Get institutions user can manage (super admin only)
  def manageable_institutions
    return Institution.none unless cohort_super_admin?
    managed_institutions
  end

  # Get institutions user can access (both roles)
  def accessible_institutions
    Institution.for_user(self)
  end
end