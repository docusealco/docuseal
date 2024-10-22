# frozen_string_literal: true

FactoryBot.define do
  factory :completed_document do
    submitter
    sha256 { SecureRandom.hex(32) }
  end
end
