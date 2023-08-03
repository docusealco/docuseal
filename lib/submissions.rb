# frozen_string_literal: true

module Submissions
  module_function

  def update_template_fields!(submission)
    submission.template_fields = submission.template.fields
    submission.template_schema = submission.template.schema
    submission.template_submitters = submission.template.submitters

    submission.save!
  end

  def create_from_emails(template:, user:, emails:, send_email: false)
    emails = emails.to_s.scan(User::EMAIL_REGEXP)

    emails.map do |email|
      submission = template.submissions.new(created_by_user: user)
      submission.submitters.new(email:, uuid: template.submitters.first['uuid'],
                                sent_at: send_email ? Time.current : nil)

      submission.tap(&:save!)
    end
  end

  def create_from_submitters(template:, user:, submissions_attrs:, send_email: false)
    submissions_attrs.map do |attrs|
      submission = template.submissions.new(created_by_user: user)

      attrs[:submitters].each_with_index do |submitter_attrs, index|
        uuid =
          submitter_attrs[:uuid].presence ||
          template.submitters.find { |e| e['name'] == submitter_attrs[:name] }&.dig('uuid') ||
          template.submitters[index]&.dig('uuid')

        submission.submitters.new(**submitter_attrs, uuid:, sent_at: send_email ? Time.current : nil)
      end

      submission.tap(&:save!)
    end
  end
end
