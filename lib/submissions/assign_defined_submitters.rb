# frozen_string_literal: true

module Submissions
  module AssignDefinedSubmitters
    module_function

    def call(submission)
      submission.submitters_order = 'preserved'

      assign_defined_submitters(submission)
      assign_linked_submitters(submission)

      submission
    end

    def assign_defined_submitters(submission)
      submission.template.submitters.to_a.select do |item|
        next if item['email'].blank? && item['is_requester'].blank?
        next if submission.submitters.any? { |e| e.uuid == item['uuid'] }

        submission.submitters.new(
          account_id: submission.account_id,
          uuid: item['uuid'],
          email: item['is_requester'] ? submission.template.author.email : item['email']
        )
      end
    end

    def assign_linked_submitters(submission)
      submission.template.submitters.to_a.select do |item|
        next if item['linked_to_uuid'].blank?
        next if submission.submitters.any? { |e| e.uuid == item['uuid'] }

        email = submission.submitters.find { |s| s.uuid == item['linked_to_uuid'] }&.email

        next unless email

        submission.submitters.new(
          account_id: submission.account_id,
          uuid: item['uuid'],
          email:
        )
      end
    end
  end
end
