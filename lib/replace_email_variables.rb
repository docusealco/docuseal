# frozen_string_literal: true

module ReplaceEmailVariables
  TEMPLATE_NAME = '{{template.name}}'
  TEMPLATE_ID = '{{template.id}}'
  SUBMITTER_LINK = '{{submitter.link}}'
  ACCOUNT_NAME = '{{account.name}}'
  SENDER_NAME = '{{sender.name}}'
  SENDER_EMAIL = '{{sender.email}}'
  SUBMITTER_EMAIL = '{{submitter.email}}'
  SUBMITTER_NAME = '{{submitter.name}}'
  SUBMITTER_ID = '{{submitter.id}}'
  SUBMITTER_SLUG = '{{submitter.slug}}'
  SUBMISSION_LINK = '{{submission.link}}'
  SUBMISSION_ID = '{{submission.id}}'
  SUBMISSION_SUBMITTERS = '{{submission.submitters}}'
  DOCUMENTS_LINKS = '{{documents.links}}'
  DOCUMENTS_LINK = '{{documents.link}}'

  module_function

  # rubocop:disable Metrics
  def call(text, submitter:, tracking_event_type: 'click_email', sig: nil)
    text = text.gsub(TEMPLATE_NAME) { submitter.template.name }
    text = text.gsub(TEMPLATE_ID) { submitter.template.id }
    text = text.gsub(SUBMITTER_ID) { submitter.id }
    text = text.gsub(SUBMITTER_SLUG) { submitter.slug }
    text = text.gsub(SUBMISSION_ID) { submitter.submission.id }
    text = text.gsub(SUBMITTER_EMAIL) { submitter.email }
    text = text.gsub(SUBMITTER_NAME) { submitter.name || submitter.email || submitter.phone }
    text = text.gsub(SUBMITTER_LINK) { build_submitter_link(submitter, tracking_event_type) }
    text = text.gsub(SUBMISSION_LINK) do
      submitter.submission ? build_submission_link(submitter.submission) : ''
    end
    text = text.gsub(SUBMISSION_SUBMITTERS) { build_submission_submitters(submitter.submission) }
    text = text.gsub(DOCUMENTS_LINKS) { build_documents_links_text(submitter, sig) }
    text = text.gsub(DOCUMENTS_LINK) { build_documents_links_text(submitter, sig) }
    text = text.gsub(ACCOUNT_NAME) { submitter.account.name }
    text = text.gsub(SENDER_NAME) { submitter.submission.created_by_user&.full_name }

    text.gsub(SENDER_EMAIL) { submitter.submission.created_by_user&.email }
  end
  # rubocop:enable Metrics

  def build_documents_links_text(submitter, sig = nil)
    Rails.application.routes.url_helpers.submissions_preview_url(
      submitter.submission.slug, { sig:, **Docuseal.default_url_options }.compact
    )
  end

  def build_submitter_link(submitter, tracking_event_type)
    if tracking_event_type == 'click_email'
      Rails.application.routes.url_helpers.submit_form_url(
        slug: submitter.slug,
        t: SubmissionEvents.build_tracking_param(submitter, 'click_email'),
        **Docuseal.default_url_options
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
    submission.submitters.order(:completed_at).map { |e| e.name || e.email || e.phone }.join(', ')
  end
end
