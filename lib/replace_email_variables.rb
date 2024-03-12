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
  def call(text, submitter:, tracking_event_type: 'click_email', html_escape: false, sig: nil)
    text = replace(text, TEMPLATE_NAME, html_escape:) { submitter.template.name }
    text = replace(text, TEMPLATE_ID, html_escape:) { submitter.template.id }
    text = replace(text, SUBMITTER_ID, html_escape:) { submitter.id }
    text = replace(text, SUBMITTER_SLUG, html_escape:) { submitter.slug }
    text = replace(text, SUBMISSION_ID, html_escape:) { submitter.submission.id }
    text = replace(text, SUBMITTER_EMAIL, html_escape:) { submitter.email }
    text = replace(text, SUBMITTER_NAME, html_escape:) { submitter.name || submitter.email || submitter.phone }
    text = replace(text, SUBMITTER_LINK, html_escape:) { build_submitter_link(submitter, tracking_event_type) }
    text = replace(text, SUBMISSION_LINK, html_escape:) do
      submitter.submission ? build_submission_link(submitter.submission) : ''
    end
    text = replace(text, SUBMISSION_SUBMITTERS, html_escape:) { build_submission_submitters(submitter.submission) }
    text = replace(text, DOCUMENTS_LINKS, html_escape:) { build_documents_links_text(submitter, sig) }
    text = replace(text, DOCUMENTS_LINK, html_escape:) { build_documents_links_text(submitter, sig) }
    text = replace(text, ACCOUNT_NAME, html_escape:) { submitter.submission.account.name }
    text = replace(text, SENDER_NAME, html_escape:) { submitter.submission.created_by_user&.full_name }

    replace(text, SENDER_EMAIL, html_escape:) { submitter.submission.created_by_user&.email.to_s.sub(/\+\w+@/, '@') }
  end
  # rubocop:enable Metrics

  def build_documents_links_text(submitter, sig = nil)
    Rails.application.routes.url_helpers.submissions_preview_url(
      submitter.submission.slug, { sig:, **Docuseal.default_url_options }.compact
    )
  end

  def replace(text, var, html_escape: false)
    text.gsub(var) do
      if html_escape
        ERB::Util.html_escape(yield)
      else
        yield
      end
    end
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
