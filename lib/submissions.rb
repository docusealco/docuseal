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

    submissions.joins(:submitters).where(arel).group(:id)
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
                                account_id: user.account_id,
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

  def send_signature_requests(submissions, delay: nil)
    submissions.each_with_index do |submission, index|
      delay_seconds = (delay + index).seconds if delay

      submitters = submission.submitters.reject(&:completed_at?)

      if submission.submitters_order_preserved?
        first_submitter =
          submission.template_submitters.filter_map { |s| submitters.find { |e| e.uuid == s['uuid'] } }.first

        Submitters.send_signature_requests([first_submitter], delay_seconds:) if first_submitter
      else
        Submitters.send_signature_requests(submitters, delay_seconds:)
      end
    end
  end

  def normalize_email(email)
    return if email.blank?

    return email.downcase if email.to_s.include?(',') ||
                             email.to_s.match?(/\.(?:gob|om|mm|cm|et|mo|nz|za|ie)\z/) ||
                             email.to_s.exclude?('.')

    fixed_email = EmailTypo.call(email.delete_prefix('<'))

    return fixed_email if fixed_email == email

    domain = email.to_s.split('@').last.to_s.downcase

    if DidYouMean::Levenshtein.distance(domain, fixed_email.to_s.split('@').last) > 3
      Rails.logger.info("Skipped email fix #{domain}")

      return email.downcase
    end

    Rails.logger.info("Fixed email #{domain}") if fixed_email != email.downcase.delete_prefix('<').strip

    fixed_email
  end

  def filtered_conditions_schema(submission, values: nil, include_submitter_uuid: nil)
    fields_uuid_index = nil

    (submission.template_schema || submission.template.schema).filter_map do |item|
      if item['conditions'].present?
        fields_uuid_index ||=
          (submission.template_fields || submission.template.fields).index_by { |f| f['uuid'] }

        values ||= submission.submitters.reduce({}) { |acc, sub| acc.merge(sub.values) }

        next unless check_document_conditions(item, values, fields_uuid_index, include_submitter_uuid:)
      end

      item
    end
  end

  def check_document_conditions(item, values, fields_index, include_submitter_uuid: nil)
    return true if item['conditions'].blank?

    item['conditions'].all? do |condition|
      result =
        if fields_index[condition['field_uuid']]['submitter_uuid'] == include_submitter_uuid
          true
        else
          Submitters::SubmitValues.check_field_condition(condition, values, fields_index)
        end

      item['conditions'].each_with_object([]) do |c, acc|
        if c['operation'] == 'or'
          acc.push(acc.pop || result)
        else
          acc.push(result)
        end
      end.exclude?(false)
    end
  end
end
