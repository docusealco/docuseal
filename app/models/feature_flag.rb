# frozen_string_literal: true

# == Schema Information
#
# Table name: feature_flags
#
#  id          :bigint           not null, primary key
#  description :text
#  enabled     :boolean          default(FALSE), not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_feature_flags_on_name  (name) UNIQUE
#
class FeatureFlag < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true

  # Check if a feature is enabled
  # @param feature_name [String, Symbol] the name of the feature flag
  # @return [Boolean] true if the feature is enabled, false otherwise
  def self.enabled?(feature_name)
    flag = find_by(name: feature_name.to_s)
    flag&.enabled || false
  end

  # Enable a feature flag
  # @param feature_name [String, Symbol] the name of the feature flag
  # @return [Boolean] true if successful
  def self.enable!(feature_name)
    flag = find_or_create_by(name: feature_name.to_s)
    flag.update(enabled: true)
  end

  # Disable a feature flag
  # @param feature_name [String, Symbol] the name of the feature flag
  # @return [Boolean] true if successful
  def self.disable!(feature_name)
    flag = find_or_create_by(name: feature_name.to_s)
    flag.update(enabled: false)
  end
end
