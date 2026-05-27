# frozen_string_literal: true

module CanCan
  module Relevant
    # Matches both the action, subject, and attribute, not necessarily the conditions
    def relevant?(action, subject)
      subject = subject.values.first if subject.class == Hash
      @match_all || (matches_action?(action) && matches_subject?(subject))
    end

    private

    def matches_action?(action)
      @expanded_actions.include?(:manage) || @expanded_actions.include?(action)
    end

    def matches_subject?(subject)
      @subjects.include?(:all) || @subjects.include?(subject) || matches_subject_class?(subject)
    end

    def matches_subject_class?(subject)
      @subjects.any? do |sub|
        sub.is_a?(Module) && (subject.is_a?(sub) ||
            subject.class.to_s == sub.to_s ||
            (subject.is_a?(Module) && subject.ancestors.include?(sub)))
      end
    end
  end
end
