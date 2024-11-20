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

    trait :with_submitters do
      after(:create) do |submission, _|
        submission.template_submitters.each do |template_submitter|
          create(:submitter, submission:,
                             account_id: submission.account_id,
                             uuid: template_submitter['uuid'],
                             created_at: submission.created_at)
        end
      end
    end

    trait :with_events do
      after(:create) do |submission, _|
        submission.submitters.each do |submitter|
          create(:submission_event, submission:, submitter:)
        end
      end
    end
  end
end
