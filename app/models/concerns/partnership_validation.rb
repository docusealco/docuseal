# frozen_string_literal: true

module PartnershipValidation
  extend ActiveSupport::Concern

  included do
    validate :must_belong_to_account_or_partnership
  end

  private

  def must_belong_to_account_or_partnership
    if account.blank? && partnership.blank?
      errors.add(:base, 'Must belong to either an account or partnership')
    elsif account.present? && partnership.present?
      errors.add(:base, 'Cannot belong to both account and partnership')
    end
  end
end
