# frozen_string_literal: true

module ReplaceEmailVariables
  TEMPLATE_NAME = /\{+template\.name\}+/i
  TEMPLATE_ID = /\{+template\.id\}+/i
  SUBMITTER_LINK = /\{+submitter\.link\}+/i
  ACCOUNT_NAME = /\{+account\.name\}+/i
  SENDER_NAME = /\{+sender\.name\}+/i
  SENDER_FIRST_NAME = /\{+sender\.first_name\}+/i
  SENDER_EMAIL = /\{+sender\.email\}+/i
  SUBMITTER_EMAIL = /\{+submitter\.email\}+/i
  SUBMITTER_NAME = /\{+submitter\.name\}+/i
  SUBMITTER_FIRST_NAME = /\{+submitter\.first_name\}+/i
  SUBMITTER_ID = /\{+submitter\.id\}+/i
  SUBMITTER_SLUG = /\{+submitter\.slug\}+/i
  SUBMITTER_FIELD_VALUE = /\{+submitter\.(?<field_name>[^}]+)\}+/i
  SUBMISSION_LINK = /\{+submission\.link\}+/i
  SUBMISSION_ID = /\{+submission\.id\}+/i
  SUBMISSION_EXPIRE_AT = /\{+submission\.expire_at\}+/i
  SUBMITTERS = /\{+(?:submission\.)?submitters\}+/i
  SUBMITTERS_N_EMAIL = /\{+submitters\[(?<index>\d+)\]\.email\}+/i
  SUBMITTERS_N_NAME = /\{+submitters\[(?<index>\d+)\]\.name\}+/i
  SUBMITTERS_N_FIRST_NAME = /\{+submitters\[(?<index>\d+)\]\.first_name\}+/i
  SUBMITTERS_N_FIELD_VALUE = /\{+submitters\[(?<index>\d+)\]\.(?<field_name>[^}]+)\}+/i
  DOCUMENTS_LINKS = /\{+documents\.links\}+/i
  DOCUMENTS_LINK = /\{+documents\.link\}+/i

  EMAIL_HOST = ENV.fetch('EMAIL_HOST', nil)

  module_function

  # rubocop:disable Metrics
  def call(text, submitter:, tracking_event_type: 'click_email', html_escape: false, sig: nil)
    text = replace(text, TEMPLATE_NAME, html_escape:) { (submitter.template || submitter.submission.template).name }
    text = replace(text, TEMPLATE_ID, html_escape:) { submitter.template.id }
    text = replace(text, SUBMITTER_ID, html_escape:) { submitter.id }
    text = replace(text, SUBMITTER_SLUG, html_escape:) { submitter.slug }
    text = replace(text, SUBMISSION_ID, html_escape:) { submitter.submission.id }
    text = replace(text, SUBMITTER_EMAIL, html_escape:) { submitter.email }
    text = replace(text, SUBMITTER_NAME, html_escape:) { submitter.name || submitter.email || submitter.phone }
    text = replace(text, SUBMITTER_FIRST_NAME, html_escape:) { submitter.first_name }
    text = replace(text, SUBMITTER_LINK, html_escape:) { build_submitter_link(submitter, tracking_event_type) }
    text = replace(text, SUBMISSION_LINK, html_escape:) do
      submitter.submission ? build_submission_link(submitter.submission) : ''
    end
    text = replace(text, SUBMITTERS, html_escape:) { build_submission_submitters(submitter.submission) }
    text = replace(text, DOCUMENTS_LINKS, html_escape:) { build_documents_links_text(submitter, sig) }
    text = replace(text, DOCUMENTS_LINK, html_escape:) { build_documents_links_text(submitter, sig) }
    text = replace(text, ACCOUNT_NAME, html_escape:) { submitter.submission.account.name }
    text = replace(text, SENDER_NAME, html_escape:) { submitter.submission.created_by_user&.full_name }
    text = replace(text, SENDER_FIRST_NAME, html_escape:) { submitter.submission.created_by_user&.first_name }

    text = replace(text, SUBMISSION_EXPIRE_AT, html_escape:) do
      if submitter.submission.expire_at
        I18n.l(submitter.submission.expire_at.in_time_zone(submitter.submission.account.timezone),
               format: :short, locale: submitter.submission.account.locale)
      end
    end

    text = replace(text, SUBMITTERS_N_NAME, html_escape:) do |match|
      build_submitters_n_field(submitter.submission, match[:index].to_i - 1, :name)
    end

    text = replace(text, SUBMITTERS_N_EMAIL, html_escape:) do |match|
      build_submitters_n_field(submitter.submission, match[:index].to_i - 1, :email)
    end

    text = replace(text, SUBMITTERS_N_FIRST_NAME, html_escape:) do |match|
      build_submitters_n_field(submitter.submission, match[:index].to_i - 1, :first_name)
    end

    text = replace(text, SUBMITTERS_N_FIELD_VALUE, html_escape:) do |match|
      build_submitters_n_field(submitter.submission, match[:index].to_i - 1, :values, match[:field_name].to_s.strip)
    end

    text = replace(text, SUBMITTER_FIELD_VALUE, html_escape:) do |match|
      submitters = submitter.submission.template_submitters || submitter.submission.template.submitters
      index = submitters.find_index { |e| e['uuid'] == submitter.uuid }

      build_submitters_n_field(submitter.submission, index, :values, match[:field_name].to_s.strip)
    end

    replace(text, SENDER_EMAIL, html_escape:) { submitter.submission.created_by_user&.email.to_s.sub(/\+\w+@/, '@') }
  end
  # rubocop:enable Metrics

  def build_documents_links_text(submitter, sig = nil)
    Rails.application.routes.url_helpers.submissions_preview_url(
      submitter.submission.slug, { sig:, **Docuseal.default_url_options }.compact
    )
  end

  def build_submitters_n_field(submission, index, field_name, value_name = nil)
    uuid = (submission.template_submitters || submission.template.submitters).dig(index, 'uuid')

    submitter = submission.submitters.find { |s| s.uuid == uuid }

    return unless submitter

    value = submitter.try(field_name)

    if value_name
      field = (submission.template_fields || submission.template.fields).find { |e| e['name'] == value_name }

      return unless field

      value =
        if field['type'].in?(%w[image signature initials stamp payment file])
          attachment_uuid = Array.wrap(value[field['uuid']]).first

          attachment = submitter.attachments.find { |e| e.uuid == attachment_uuid }

          ActiveStorage::Blob.proxy_url(attachment.blob) if attachment
        else
          value[field&.dig('uuid')]
        end
    end

    value
  end

  def replace(text, var, html_escape: false)
    text.gsub(var) do
      if html_escape
        ERB::Util.html_escape(yield(Regexp.last_match))
      else
        yield(Regexp.last_match)
      end
    end
  end

  def build_submitter_link(submitter, tracking_event_type)
    if tracking_event_type == 'click_email'
      url_options =
        if EMAIL_HOST.present?
          { host: EMAIL_HOST, protocol: ENV['FORCE_SSL'].present? ? 'https' : 'http' }
        else
          Docuseal.default_url_options
        end

      Rails.application.routes.url_helpers.submit_form_url(
        slug: submitter.slug,
        t: SubmissionEvents.build_tracking_param(submitter, 'click_email'),
        **url_options
      )
    else
      Rails.application.routes.url_helpers.submit_form_url(
        slug: submitter.slug,
        c: SubmissionEvents.build_tracking_param(submitter, 'click_sms'),
        **Docuseal.default_url_options
      )
    end
  end

  def build_submission_link(submission)
    Rails.application.routes.url_helpers.submission_url(submission, **Docuseal.default_url_options)
  end

  def build_submission_submitters(submission)
    submission.submitters.order(:completed_at).map { |e| e.name || e.email || e.phone }.uniq.join(', ')
  end
end
