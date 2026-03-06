# frozen_string_literal: true

class SubmitFormValuesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def index
    submitter = Submitter.find_by!(slug: params[:submit_form_slug])

    return render json: {} if submitter.completed_at? ||
                              submitter.declined_at? ||
                              submitter.submission.template&.archived_at? ||
                              submitter.submission.archived_at? ||
                              submitter.submission.expired? ||
                              !Submitters::AuthorizedForForm.call(submitter, current_user, request)

    value = submitter.values[params['field_uuid']]
    attachment = submitter.attachments.where(created_at: params[:after]..).find_by(uuid: value) if value.present?

    render json: {
      value:,
      attachment: attachment&.as_json(only: %i[uuid created_at], methods: %i[url filename content_type])
    }, head: :ok
  end
end
