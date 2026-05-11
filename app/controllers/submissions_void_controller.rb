# frozen_string_literal: true

class SubmissionsVoidController < ApplicationController
  load_and_authorize_resource :submission

  before_action only: %i[new create] do
    authorize!(:destroy, @submission)
  end

  def new
    render layout: false
  end

  def create
    Submissions::Void.call(@submission, user: current_user, reason: params[:reason], request:)

    redirect_to submission_path(@submission), notice: I18n.t('submission_has_been_voided')
  rescue Submissions::Void::ReasonRequiredError, Submissions::Void::NotVoidableError => e
    redirect_to submission_path(@submission), alert: e.message
  end
end
