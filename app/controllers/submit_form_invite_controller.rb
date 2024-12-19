# frozen_string_literal: true

class SubmitFormInviteController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def create
    submitter = Submitter.find_by!(slug: params[:submit_form_slug])

    return head :unprocessable_entity unless can_invite?(submitter)

    invite_submitters = filter_invite_submitters(submitter, 'invite_by_uuid')
    optional_invite_submitters = filter_invite_submitters(submitter, 'optional_invite_by_uuid')

    ApplicationRecord.transaction do
      (invite_submitters + optional_invite_submitters).each do |item|
        attrs = submitters_attributes.find { |e| e[:uuid] == item['uuid'] }

        next unless attrs
        next if attrs[:email].blank?

        submitter.submission.submitters.create!(**attrs, account_id: submitter.account_id)

        SubmissionEvents.create_with_tracking_data(submitter, 'invite_party', request, { uuid: submitter.uuid })
      end

      submitter.submission.update!(submitters_order: :preserved)
    end

    submitter.submission.submitters.reload

    if invite_submitters.all? { |s| submitter.submission.submitters.any? { |e| e.uuid == s['uuid'] } }
      Submitters::SubmitValues.call(submitter, ActionController::Parameters.new(completed: 'true'), request)

      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def can_invite?(submitter)
    !submitter.declined_at? &&
      !submitter.completed_at? &&
      !submitter.submission.archived_at? &&
      !submitter.submission.expired? &&
      !submitter.submission.template.archived_at?
  end

  def filter_invite_submitters(submitter, key = 'invite_by_uuid')
    (submitter.submission.template_submitters || submitter.submission.template.submitters).select do |s|
      s[key] == submitter.uuid && submitter.submission.submitters.none? { |e| e.uuid == s['uuid'] }
    end
  end

  def submitters_attributes
    params.require(:submission).permit(submitters: [%i[uuid email]]).fetch(:submitters, [])
  end
end
