# frozen_string_literal: true

class SubmitFormDrawSignatureController < ApplicationController
  layout false

  around_action :with_browser_locale, only: %i[show]
  skip_before_action :authenticate_user!
  skip_authorization_check

  def show
    @submitter = Submitter.find_by!(slug: params[:slug])

    return redirect_to submit_form_completed_path(@submitter.slug) if @submitter.completed_at?

    if @submitter.submission.template.archived_at? || @submitter.submission.archived_at?
      return redirect_to submit_form_path(@submitter.slug)
    end

    render :show
  end
end
