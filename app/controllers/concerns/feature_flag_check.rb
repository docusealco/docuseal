# frozen_string_literal: true

# FeatureFlagCheck Concern
# Purpose: Provides before_action helpers to check feature flags in controllers
# Usage: include FeatureFlagCheck in controllers that need feature flag protection
module FeatureFlagCheck
  extend ActiveSupport::Concern

  included do
    # Helper method available in controllers
  end

  class_methods do
    # Add a before_action to require a feature flag
    # @param feature_name [Symbol, String] the name of the feature flag
    # @param options [Hash] options to pass to before_action
    # @example
    #   before_action :require_feature(:flodoc_cohorts)
    def require_feature(feature_name, **options)
      before_action(**options) do
        check_feature_flag(feature_name)
      end
    end
  end

  private

  # Check if a feature flag is enabled, render 404 if not
  # @param feature_name [Symbol, String] the name of the feature flag
  def check_feature_flag(feature_name)
    return if FeatureFlag.enabled?(feature_name)

    render json: { error: 'Feature not available' }, status: :not_found
  end

  # Check if a feature is enabled (for use in views/controllers)
  # @param feature_name [Symbol, String] the name of the feature flag
  # @return [Boolean] true if enabled
  def feature_enabled?(feature_name)
    FeatureFlag.enabled?(feature_name)
  end
  helper_method :feature_enabled? if respond_to?(:helper_method)
end
