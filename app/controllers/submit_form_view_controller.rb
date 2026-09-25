# frozen_string_literal: true

class SubmitFormViewController < ActionController::API
  def create
    @submitter = Submitter.find_by!(slug: params[:submit_form_slug])

    return head :not_found if Submitter.signed_id_verifier.verified(params[:v], purpose: :view_form) != @submitter.slug

    @submitter.opened_at = Time.current
    @submitter.save

    SubmissionEvents.create_with_tracking_data(@submitter, 'view_form', request)

    WebhookUrls.enqueue_events(@submitter, 'form.viewed')

    render json: {}
  end
end
