# frozen_string_literal: true

module Submissions
  DEFAULT_SUBMITTERS_ORDER = 'random'

  module_function

  def search(submissions, keyword)
    return submissions if keyword.blank?

    term = "%#{keyword.downcase}%"

    arel_table = Submitter.arel_table

    arel = arel_table[:email].lower.matches(term)
                             .or(arel_table[:phone].matches(term))
                             .or(arel_table[:name].lower.matches(term))

    submissions.joins(:submitters).where(arel).distinct
  end

  def update_template_fields!(submission)
    submission.template_fields = submission.template.fields
    submission.template_schema = submission.template.schema
    submission.template_submitters = submission.template.submitters if submission.template_submitters.blank?

    submission.save!
  end

  def create_from_emails(template:, user:, emails:, source:, mark_as_sent: false)
    emails = emails.to_s.scan(User::EMAIL_REGEXP) unless emails.is_a?(Array)

    emails.uniq.map do |email|
      submission = template.submissions.new(created_by_user: user, source:, template_submitters: template.submitters)
      submission.submitters.new(email: normalize_email(email),
                                uuid: template.submitters.first['uuid'],
                                sent_at: mark_as_sent ? Time.current : nil)

      submission.tap(&:save!)
    end
  end

  def create_from_submitters(template:, user:, submissions_attrs:, source:, mark_as_sent: false,
                             submitters_order: DEFAULT_SUBMITTERS_ORDER)
    Submissions::CreateFromSubmitters.call(
      template:, user:, submissions_attrs:, source:, mark_as_sent:, submitters_order:
    )
  end

  def send_signature_requests(submissions, params)
    submissions.each do |submission|
      if submission.submitters_order_preserved?
        first_submitter = submission.submitters.find { |e| e.uuid == submission.template_submitters.first['uuid'] }

        Submitters.send_signature_requests([first_submitter], params)
      else
        Submitters.send_signature_requests(submission.submitters, params)
      end
    end
  end

  def normalize_email(email)
    return if email.blank?
    return email.downcase if email.to_s.include?(',')

    EmailTypo.call(email.delete_prefix('<'))
  end
end
