# frozen_string_literal: true

module Submissions
  DEFAULT_SUBMITTERS_ORDER = 'random'

  PRELOAD_ALL_PAGES_AMOUNT = 200

  module_function

  def search(submissions, keyword, search_values: false, search_template: false)
    return submissions if keyword.blank?

    term = "%#{keyword.downcase}%"

    arel_table = Submitter.arel_table

    arel = arel_table[:email].lower.matches(term)
                             .or(arel_table[:phone].matches(term))
                             .or(arel_table[:name].lower.matches(term))

    arel = arel.or(Arel::Table.new(:submitters)[:values].matches(term)) if search_values

    if search_template
      submissions = submissions.joins(:template)

      arel = arel.or(Template.arel_table[:name].lower.matches("%#{keyword.downcase}%"))
    end

    submissions.joins(:submitters).where(arel).distinct
  end

  def update_template_fields!(submission)
    submission.template_fields = submission.template.fields
    submission.template_schema = submission.template.schema
    submission.template_submitters = submission.template.submitters if submission.template_submitters.blank?

    submission.save!
  end

  def preload_with_pages(submission)
    ActiveRecord::Associations::Preloader.new(
      records: [submission],
      associations: [:template, { template_schema_documents: :blob }]
    ).call

    total_pages =
      submission.template_schema_documents.sum { |e| e.metadata.dig('pdf', 'number_of_pages').to_i }

    if total_pages < PRELOAD_ALL_PAGES_AMOUNT
      ActiveRecord::Associations::Preloader.new(
        records: submission.template_schema_documents,
        associations: [:blob, { preview_images_attachments: :blob }]
      ).call
    end

    submission
  end

  def create_from_emails(template:, user:, emails:, source:, mark_as_sent: false, params: {})
    preferences = Submitters.normalize_preferences(user.account, user, params)

    parse_emails(emails, user).uniq.map do |email|
      submission = template.submissions.new(created_by_user: user,
                                            account_id: user.account_id,
                                            source:,
                                            template_submitters: template.submitters)

      submission.submitters.new(email: normalize_email(email),
                                uuid: template.submitters.first['uuid'],
                                preferences:,
                                sent_at: mark_as_sent ? Time.current : nil)

      submission.tap(&:save!)
    end
  end

  def parse_emails(emails, _user)
    emails = emails.to_s.scan(User::EMAIL_REGEXP) unless emails.is_a?(Array)

    emails
  end

  def create_from_submitters(template:, user:, submissions_attrs:, source:,
                             submitters_order: DEFAULT_SUBMITTERS_ORDER, params: {})
    Submissions::CreateFromSubmitters.call(
      template:, user:, submissions_attrs:, source:, submitters_order:, params:
    )
  end

  def send_signature_requests(submissions)
    submissions.each do |submission|
      submitters = submission.submitters.reject(&:completed_at?)

      if submission.submitters_order_preserved?
        first_submitter =
          submission.template_submitters.filter_map { |s| submitters.find { |e| e.uuid == s['uuid'] } }.first

        Submitters.send_signature_requests([first_submitter]) if first_submitter
      else
        Submitters.send_signature_requests(submitters)
      end
    end
  end

  def normalize_email(email)
    return if email.blank?
    return email.downcase if email.to_s.include?(',')
    return email.downcase if email.to_s.include?('.gob')
    return email.downcase if email.to_s.include?('.om')
    return email.downcase if email.to_s.include?('.mm')
    return email.downcase if email.to_s.include?('.cm')
    return email.downcase unless email.to_s.include?('.')

    fixed_email = EmailTypo.call(email.delete_prefix('<'))

    if defined?(Rollbar) && fixed_email != email.downcase.delete_prefix('<').strip
      Rollbar.warning("Fixed email #{email}")
    end

    fixed_email
  end
end
