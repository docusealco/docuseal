# frozen_string_literal: true

class SubmissionsDebugController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!

  def index
    @submission = Submission.preload({ attachments_attachments: :blob },
                                     template: { documents_attachments: :blob })
                            .find_by(slug: params[:submission_slug])

    respond_to do |f|
      f.html do
        render 'submit_template/show'
      end
      f.pdf do
        Submissions::GenerateResultAttachments.call(@submission)

        send_data ActiveStorage::Attachment.where(name: :documents).last.download,
                  filename: 'debug.pdf',
                  disposition: 'inline',
                  type: 'application/pdf'
      end
    end
  end
end
