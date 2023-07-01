# frozen_string_literal: true

class GenerateSubmitterResultAttachmentsJob < ApplicationJob
  def perform(submitter)
    Submissions::EnsureResultGenerated.call(submitter)
  end
end
