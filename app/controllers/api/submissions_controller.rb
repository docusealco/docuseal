# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    UnknownFieldName = Class.new(StandardError)
    UnknownSubmitterName = Class.new(StandardError)

    def create
      template = current_account.templates.find(params[:template_id])

      submissions =
        if (emails = (params[:emails] || params[:email]).presence)
          Submissions.create_from_emails(template:,
                                         user: current_user,
                                         source: :api,
                                         mark_as_sent: params[:send_email] != 'false',
                                         emails:)
        else
          submissions_attrs = normalize_submissions_params!(submissions_params[:submission], template)

          Submissions.create_from_submitters(
            template:,
            user: current_user,
            source: :api,
            mark_as_sent: params[:send_email] != 'false',
            submitters_order: params[:submitters_order] || 'preserved',
            submissions_attrs:
          )
        end

      Submissions.send_signature_requests(submissions, send_email: params[:send_email] != 'false')

      render json: submissions.flat_map(&:submitters)
    rescue UnknownFieldName, UnknownSubmitterName => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def submissions_params
      params.permit(submission: [{ submitters: [[:uuid, :name, :email, :role, :phone, { values: {} }]] }])
    end

    def normalize_submissions_params!(submissions_params, template)
      submissions_params.each do |submission|
        submission[:submitters].each_with_index do |submitter, index|
          next if submitter[:values].blank?

          submitter[:values] =
            normalize_submitter_values(template,
                                       submitter[:values],
                                       submitter[:role] || template.submitters[index]['name'])
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
