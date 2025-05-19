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

    expire_at = params[:expire_at].presence || Templates.build_default_expire_at(template)

    parse_emails(emails, user).uniq.map do |email|
      submission = template.submissions.new(created_by_user: user,
                                            account_id: user.account_id,
                                            source:,
                                            expire_at:,
                                            template_submitters: template.submitters)

      submission.submitters.new(email: normalize_email(email),
                                uuid: template.submitters.first['uuid'],
                                account_id: user.account_id,
                                preferences:,
                                sent_at: mark_as_sent ? Time.current : nil)

      submission.save!

      if submission.expire_at?
        ProcessSubmissionExpiredJob.perform_at(submission.expire_at, 'submission_id' => submission.id)
      end

      submission
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
    return if email.is_a?(Numeric)

    email = email.to_s.tr('/', ',')

    return email.downcase if email.include?(',') ||
                             email.match?(/\.(?:gob|om|mm|cm|et|mo|nz|za|ie)\z/) ||
                             email.exclude?('.')

    fixed_email = EmailTypo.call(email.delete_prefix('<'))

    return fixed_email if fixed_email == email

    domain = email.split('@').last.to_s.downcase
    fixed_domain = fixed_email.to_s.split('@').last

    return email.downcase if domain == fixed_domain
    return email.downcase if fixed_domain.match?(/\Agmail\.(?!com\z)/i)

    if DidYouMean::Levenshtein.distance(domain, fixed_domain) > 3
      Rails.logger.info("Skipped email fix #{domain}")

      return email.downcase
    end

    Rails.logger.info("Fixed email #{domain}") if fixed_email != email.downcase.delete_prefix('<').strip

    fixed_email
  end

  def filtered_conditions_schema(submission, values: nil, include_submitter_uuid: nil)
    (submission.template_schema || submission.template.schema).filter_map do |item|
      if item['conditions'].present?
        values ||= submission.submitters.reduce({}) { |acc, sub| acc.merge(sub.values) }

        next unless check_item_conditions(item, values, submission.fields_uuid_index, include_submitter_uuid:)
      end

      item
    end
  end

  def filtered_conditions_fields(submitter, only_submitter_fields: true)
    submission = submitter.submission

    fields = submission.template_fields || submission.template.fields

    values = nil

    fields.filter_map do |field|
      next if field['submitter_uuid'] != submitter.uuid && only_submitter_fields

      if field['conditions'].present?
        values ||= submission.submitters.reduce({}) { |acc, sub| acc.merge(sub.values) }

        submitter_conditions = []

        next unless check_item_conditions(field, values, submission.fields_uuid_index,
                                          include_submitter_uuid: submitter.uuid,
                                          submitter_conditions_acc: submitter_conditions)

        field = field.merge('conditions' => submitter_conditions) if submitter_conditions != field['conditions']
      end

      field
    end
  end

  def check_item_conditions(item, values, fields_index, include_submitter_uuid: nil, submitter_conditions_acc: nil)
    return true if item['conditions'].blank?

    item['conditions'].each_with_object([]) do |condition, acc|
      result =
        if fields_index[condition['field_uuid']]['submitter_uuid'] == include_submitter_uuid
          submitter_conditions_acc << condition if submitter_conditions_acc

          true
        else
          Submitters::SubmitValues.check_field_condition(condition, values, fields_index)
        end

      if condition['operation'] == 'or'
        acc.push(acc.pop || result)
      else
        acc.push(result)
      end
    end.exclude?(false)
  end

  def regenerate_documents(submission)
    submitters = submission.submitters.where.not(completed_at: nil).preload(:documents_attachments)

    submitters.each { |submitter| submitter.documents.each(&:destroy!) }

    submission.submitters.where.not(completed_at: nil).order(:completed_at).each do |submitter|
      GenerateResultAttachments.call(submitter)
    end

    return if submission.combined_document_attachment.blank?

    submission.combined_document_attachment.destroy!

    Submissions::GenerateCombinedAttachment.call(submission.submitters.completed.order(:completed_at).last)
  end
end
