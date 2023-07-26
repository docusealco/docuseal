# frozen_string_literal: true

module Submissions
  module_function

  def update_template_fields!(submission)
    submission.template_fields = submission.template.fields
    submission.template_schema = submission.template.schema
    submission.template_submitters = submission.template.submitters

    submission.save!
  end
end
