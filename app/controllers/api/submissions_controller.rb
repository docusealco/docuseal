# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    def create
      template = current_account.templates.find(params[:template_id])

      submissions =
        if params[:emails].present?
          Submissions.create_from_emails(template:,
                                         user: current_user,
                                         source: :api,
                                         send_email: params[:send_email] != 'false',
                                         emails: params[:emails])
        else
          Submissions.create_from_submitters(template:,
                                             user: current_user,
                                             source: :api,
                                             send_email: params[:send_email] != 'false',
                                             submissions_attrs: submissions_params[:submission])
        end

      submitters = submissions.flat_map(&:submitters)

      if params[:send_email] != 'false'
        submitters.each do |submitter|
          SubmitterMailer.invitation_email(submitter, message: params[:message]).deliver_later!
        end
      end

      render json: submitters
    end

    private

    def submissions_params
      params.permit(submission: [{ submitters: [%i[uuid name email]] }])
    end
  end
end
