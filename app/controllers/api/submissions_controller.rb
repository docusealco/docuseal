# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    UnknownFieldName = Class.new(StandardError)
    UnknownSubmitterName = Class.new(StandardError)

    def create
      template = current_account.templates.find(params[:template_id])

      submissions =
        if params[:emails].present?
          Submissions.create_from_emails(template:,
                                         user: current_user,
                                         source: :api,
                                         send_email: params[:send_email] != 'false',
                                         emails: params[:emails] || params[:email])
        else
          submissions_attrs = normalize_submissions_params!(submissions_params[:submission], template)

          Submissions.create_from_submitters(template:,
                                             user: current_user,
                                             source: :api,
                                             send_email: params[:send_email] != 'false',
                                             submissions_attrs:)
        end

      submitters = submissions.flat_map(&:submitters)

      send_invitation_emails(submitters) if params[:send_email] != 'false'

      render json: submitters
    rescue UnknownFieldName, UnknownSubmitterName => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def send_invitation_emails(submitters)
      submitters.each do |submitter|
        SubmitterMailer.invitation_email(submitter, message: params[:message]).deliver_later!
      end
    end

    def submissions_params
      params.permit(submission: [{ submitters: [[:uuid, :name, :email, { values: {} }]] }])
    end

    def normalize_submissions_params!(submissions_params, template)
      submissions_params.each do |submission|
        submission[:submitters].each_with_index do |submitter, index|
          next if submitter[:values].blank?

          submitter[:values] =
            normalize_submitter_values(template,
                                       submitter[:values], submitter[:name] || template.submitters[index]['name'])
        end
      end

      submissions_params
    end

    def normalize_submitter_values(template, values, submitter_name)
      submitter =
        template.submitters.find { |e| e['name'] == submitter_name } ||
        raise(UnknownSubmitterName, "Unknown submitter: #{submitter_name}")

      fields = template.fields.select { |e| e['submitter_uuid'] == submitter['uuid'] }

      fields_uuid_index = fields.index_by { |e| e['uuid'] }
      fields_name_index = fields.index_by { |e| e['name'] }

      values.transform_keys do |key|
        next key if fields_uuid_index[key].present?

        fields_name_index[key]&.dig('uuid') || raise(UnknownFieldName, "Unknown field: #{key}")
      end
    end
  end
end
