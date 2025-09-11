# frozen_string_literal: true

module AccountGroupValidation
  extend ActiveSupport::Concern

  included do
    validate :must_belong_to_account_or_account_group
  end

  private

  def must_belong_to_account_or_account_group
    if account.blank? && account_group.blank?
      errors.add(:base, 'Must belong to either an account or account group')
    elsif account.present? && account_group.present?
      errors.add(:base, 'Cannot belong to both account and account group')
    end
  end
end
