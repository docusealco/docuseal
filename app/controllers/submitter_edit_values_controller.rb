# frozen_string_literal: true

class SubmitterEditValuesController < ApplicationController
  NON_EDITABLE_TYPES = %w[signature initials image stamp file payment verification kba heading strikethrough].freeze

  before_action :load_and_authorize_submitter

  def edit
    all_fields = @submitter.submission.template_fields || @submitter.submission.template.fields
    @fields = all_fields.select { |f| f['submitter_uuid'] == @submitter.uuid }
                        .reject { |f| NON_EDITABLE_TYPES.include?(f['type']) }
  end

  def update
    all_fields = @submitter.submission.template_fields || @submitter.submission.template.fields
    editable_fields = all_fields.select { |f| f['submitter_uuid'] == @submitter.uuid }
                                .reject { |f| NON_EDITABLE_TYPES.include?(f['type']) }
    editable_uuids = editable_fields.map { |f| f['uuid'] }

    submitted_values = params[:values].to_unsafe_h.slice(*editable_uuids)

    ActiveRecord::Base.transaction do
      @submitter.update!(values: @submitter.values.merge(submitted_values))

      @submitter.documents.each(&:purge)

      SubmissionEvent.create!(
        submitter: @submitter,
        event_type: :admin_edit_values,
        data: { user_id: current_user.id, user_email: current_user.email, updated_uuids: editable_uuids }
      )
    end

    Submissions::GenerateResultAttachments.call(@submitter)

    redirect_to submission_path(@submitter.submission),
                notice: I18n.t('submission_values_have_been_updated')
  end

  private

  def load_and_authorize_submitter
    @submitter = Submitter.find(params[:id])
    authorize! :update, @submitter.submission
  end
end
