# frozen_string_literal: true

class SubmittersResubmitController < ApplicationController
  load_and_authorize_resource :submitter, parent: false

  def update
    return redirect_to submit_form_path(slug: @submitter.slug) if @submitter.email != current_user.email

    submission = @submitter.account.submissions.new(created_by_user: current_user,
                                                    submitters_order: :preserved,
                                                    **@submitter.submission.slice(:template_fields,
                                                                                  :account_id,
                                                                                  :name,
                                                                                  :template_id,
                                                                                  :template_schema,
                                                                                  :template_submitters,
                                                                                  :preferences))

    @submitter.submission.submitters.each do |submitter|
      new_submitter = submission.submitters.new(submitter.slice(:uuid, :email, :phone, :name,
                                                                :preferences, :metadata, :account_id))

      next unless submitter.uuid == @submitter.uuid

      assign_submitter_values(new_submitter, submitter)

      @new_submitter ||= new_submitter
    end

    submission.save!

    @submitter.submission.documents_attachments.each do |attachment|
      submission.documents_attachments.create!(uuid: attachment.uuid, blob_id: attachment.blob_id)
    end

    redirect_to submit_form_path(slug: @new_submitter.slug)
  end

  private

  def assign_submitter_values(new_submitter, submitter)
    attachments_index = submitter.attachments.index_by(&:uuid)

    submitter.submission.template_fields.each do |field|
      next if field['submitter_uuid'] != submitter.uuid
      next if field['default_value'] == '{{date}}'
      next if field['type'] == 'stamp'
      next if field['type'] == 'signature'
      next if field.dig('preferences', 'formula').present?

      value = submitter.values[field['uuid']]

      next if value.blank?

      if field['type'].in?(%w[image file initials])
        Array.wrap(value).each do |attachment_uuid|
          new_submitter.attachments << attachments_index[attachment_uuid].dup
        end
      end

      new_submitter.values[field['uuid']] = value
    end
  end
end
