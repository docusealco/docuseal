# frozen_string_literal: true

module ReplaceEmailVariables
  TEMAPLTE_NAME = '{{template.name}}'
  SUBMITTER_LINK = '{{submitter.link}}'
  ACCOUNT_NAME = '{{account.name}}'
  SUBMITTER_EMAIL = '{{submitter.email}}'
  SUBMITTER_NAME = '{{submitter.name}}'
  SUBMISSION_LINK = '{{submission.link}}'
  SUBMISSION_SUBMITTERS = '{{submission.submitters}}'
  DOCUMENTS_LINKS = '{{documents.links}}'

  module_function

  def call(text, submitter:)
    submitter_link = build_submitter_link(submitter)

    submission_link = build_submission_link(submitter.submission) if submitter.submission

    text = text.gsub(TEMAPLTE_NAME, submitter.template.name) if submitter.template
    text = text.gsub(SUBMITTER_EMAIL, submitter.email) if submitter.email
    text = text.gsub(SUBMITTER_NAME, submitter.name || submitter.email || submitter.phone)
    text = text.gsub(SUBMITTER_LINK, submitter_link)
    text = text.gsub(SUBMISSION_LINK, submission_link) if submission_link
    if text.include?(SUBMISSION_SUBMITTERS)
      text = text.gsub(SUBMISSION_SUBMITTERS, build_submission_submitters(submission))
    end
    text = text.gsub(DOCUMENTS_LINKS, build_documents_links_text(submitter))

    text = text.gsub(ACCOUNT_NAME, submitter.template.account.name) if submitter.template

    text
  end

  def build_documents_links_text(submitter)
    submitter.documents.map do |document|
      link =
        Rails.application.routes.url_helpers.rails_blob_url(
          document, **Docuseal.default_url_options
        )

      "#{link}\n"
    end.join
  end

  def build_submitter_link(submitter)
    Rails.application.routes.url_helpers.submit_form_url(
      slug: submitter.slug, **Docuseal.default_url_options
    )
  end

  def build_submission_link(submission)
    Rails.application.routes.url_helpers.submission_url(submission, **Docuseal.default_url_options)
  end

  def build_submission_submitters(submission)
    submission.submitters.order(:completed_at).map { |e| e.name || e.email || e.phone }.join(', ')
  end
end
