# frozen_string_literal: true

class SubmissionsDebugController < ApplicationController
  layout 'plain'

  skip_before_action :authenticate_user!
  skip_authorization_check

  def index
    @submitter = Submitter.preload({ attachments_attachments: :blob },
                                   submission: { template: { documents_attachments: :blob } })
                          .find_by(slug: params[:submitter_slug])

    respond_to do |f|
      f.html do
        render 'submit_form/show'
      end
      f.pdf do
        result =
          if params[:audit]
            Submissions::GenerateAuditTrail.call(@submitter.submission)
          elsif params[:combined]
            Submissions::GenerateCombinedAttachment.call(@submitter)
          else
            Submissions::GenerateResultAttachments.call(@submitter)
          end

        send_data Array.wrap(result).first.download,
                  filename: 'debug.pdf',
                  disposition: 'inline',
                  type: 'application/pdf'
      end
    end
  end
end
