# frozen_string_literal: true

# Factory definitions for FloDoc models
FactoryBot.define do
  factory :feature_flag do
    sequence(:name) { |n| "feature_#{n}" }
    enabled { false }
    description { 'Test feature flag' }
  end

  factory :institution do
    sequence(:name) { |n| "Institution #{n}" }
    sequence(:email) { |n| "institution#{n}@example.com" }
    contact_person { 'John Doe' }
    phone { '+27123456789' }
    settings { {} }
    deleted_at { nil }
  end

  factory :cohort do
    association :institution
    association :template
    sequence(:name) { |n| "Cohort #{n}" }
    program_type { 'learnership' }
    sequence(:sponsor_email) { |n| "sponsor#{n}@example.com" }
    required_student_uploads { [] }
    cohort_metadata { {} }
    status { 'draft' }
    tp_signed_at { nil }
    students_completed_at { nil }
    sponsor_completed_at { nil }
    finalized_at { nil }
    deleted_at { nil }

    trait :active do
      status { 'active' }
      tp_signed_at { Time.current }
    end

    trait :completed do
      status { 'completed' }
      tp_signed_at { Time.current }
      students_completed_at { Time.current }
      sponsor_completed_at { Time.current }
      finalized_at { Time.current }
    end
  end

  factory :cohort_enrollment do
    association :cohort
    association :submission
    sequence(:student_email) { |n| "student#{n}@example.com" }
    student_name { 'John' }
    student_surname { 'Doe' }
    sequence(:student_id) { |n| "STU#{n.to_s.rjust(6, '0')}" }
    status { 'waiting' }
    role { 'student' }
    uploaded_documents { {} }
    values { {} }
    completed_at { nil }
    deleted_at { nil }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :complete do
      status { 'complete' }
      completed_at { Time.current }
    end

    trait :sponsor do
      role { 'sponsor' }
    end
  end
end
