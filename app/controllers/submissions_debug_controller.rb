# frozen_string_literal: true

class SubmissionsDebugController < ApplicationController
  layout 'plain'

  skip_before_action :authenticate_user!

  def index
    @submitter = Submitter.preload({ attachments_attachments: :blob },
                                   submission: { template: { documents_attachments: :blob } })
                          .find_by(slug: params[:submitter_slug])

    respond_to do |f|
      f.html do
        render 'submit_form/show'
      end
      f.pdf do
        Submissions::GenerateResultAttachments.call(@submitter)

        send_data ActiveStorage::Attachment.where(name: :documents).last.download,
                  filename: 'debug.pdf',
                  disposition: 'inline',
                  type: 'application/pdf'
      end
    end
  end
end
