# frozen_string_literal: true

module ReplaceEmailVariables
  TEMAPLTE_NAME = '{{template.name}}'
  SUBMITTER_LINK = '{{submitter.link}}'
  ACCOUNT_NAME = '{{account.name}}'

  module_function

  def call(text, submitter:)
    link =
      Rails.application.routes.url_helpers.submit_form_url(
        slug: submitter.slug, **Docuseal.default_url_options
      )

    text = text.gsub(TEMAPLTE_NAME, submitter.template.name)
    text = text.gsub(SUBMITTER_LINK, link)

    text.gsub(ACCOUNT_NAME, submitter.template.account.name)
  end
end
