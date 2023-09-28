# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    load_and_authorize_resource :template

    before_action do
      authorize!(:create, Submission)
    end

    def create
      is_send_email = !params[:send_email].in?(['false', false])

      submissions =
        if (emails = (params[:emails] || params[:email]).presence) && params[:submission].blank?
          Submissions.create_from_emails(template: @template,
                                         user: current_user,
                                         source: :api,
                                         mark_as_sent: is_send_email,
                                         emails:)
        else
          submissions_attrs, attachments = normalize_submissions_params!(submissions_params[:submission], @template)

          Submissions.create_from_submitters(
            template: @template,
            user: current_user,
            source: :api,
            mark_as_sent: is_send_email,
            submitters_order: params[:submitters_order] || 'preserved',
            submissions_attrs:
          )
        end

      Submissions.send_signature_requests(submissions, send_email: is_send_email)

      submitters = submissions.flat_map(&:submitters)

      save_default_value_attachments!(attachments, submitters)

      render json: submitters
    rescue Submitters::NormalizeValues::UnknownFieldName, Submitters::NormalizeValues::UnknownSubmitterName => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def submissions_params
      params.permit(submission: [{
                      submitters: [[:uuid, :name, :email, :role, :completed, :phone, { values: {} }]]
                    }])
    end

    def normalize_submissions_params!(submissions_params, template)
      attachments = []

      Array.wrap(submissions_params).each do |submission|
        submission[:submitters].each_with_index do |submitter, index|
          next if submitter[:values].blank?

          values, new_attachments =
            Submitters::NormalizeValues.call(template,
                                             submitter[:values],
                                             submitter[:role] || template.submitters[index]['name'])

          attachments.push(*new_attachments)

          submitter[:values] = values
        end
      end

      [submissions_params, attachments]
    end

    def save_default_value_attachments!(attachments, submitters)
      return if attachments.blank?

      attachments_index = attachments.index_by(&:uuid)

      submitters.each do |submitter|
        submitter.values.to_a.each do |_, value|
          attachment = attachments_index[value]

          next unless attachment

          attachment.record = submitter

          attachment.save!
        end
      end
    end
  end
end
