# frozen_string_literal: true

class SubmitFormController < ApplicationController
  layout 'form'

  skip_before_action :authenticate_user!

  def show
    @submitter =
      Submitter.preload(submission: { template: { documents_attachments: { preview_images_attachments: :blob } } })
               .find_by!(slug: params[:slug])

    return redirect_to submit_form_completed_path(@submitter.slug) if @submitter.completed_at?
  end

  def update
    submitter = Submitter.find_by!(slug: params[:slug])
    submitter.values.merge!(normalized_values)
    submitter.completed_at = Time.current if params[:completed] == 'true'

    submitter.save

    head :ok
  end

  def completed
    @submitter = Submitter.find_by!(slug: params[:submit_form_slug])
  end

  private

  def normalized_values
    params[:values].to_unsafe_h.transform_values { |v| v.is_a?(Array) ? v.compact_blank : v }
  end
end
