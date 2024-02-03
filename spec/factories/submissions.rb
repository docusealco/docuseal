# frozen_string_literal: true

FactoryBot.define do
  factory :submission do
    template
    created_by_user factory: %i[user]

    before(:create) do |submission, _|
      submission.account_id = submission.template.account_id
      submission.template_fields = submission.template.fields
      submission.template_schema = submission.template.schema
      submission.template_submitters = submission.template.submitters
    end
  end
end
