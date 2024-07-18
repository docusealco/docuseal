# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    load_and_authorize_resource :template, only: :create
    load_and_authorize_resource :submission, only: %i[show index destroy]

    before_action only: :create do
      authorize!(:create, Submission)
    end

    def index
      submissions = Submissions.search(@submissions, params[:q])
      submissions = submissions.where(template_id: params[:template_id]) if params[:template_id].present?

      if params[:template_folder].present?
        submissions = submissions.joins(template: :folder).where(folder: { name: params[:template_folder] })
      end

      submissions = paginate(submissions.preload(:created_by_user, :submitters,
                                                 template: :folder,
                                                 audit_trail_attachment: :blob))

      render json: {
        data: submissions.as_json(Submissions::SerializeForApi::SERIALIZE_PARAMS),
        pagination: {
          count: submissions.size,
          next: submissions.last&.id,
          prev: submissions.first&.id
        }
      }
    end

    def show
      submitters = @submission.submitters.preload(documents_attachments: :blob, attachments_attachments: :blob)

      submitters.each do |submitter|
        if submitter.completed_at? && submitter.documents_attachments.blank?
          submitter.documents_attachments = Submissions::EnsureResultGenerated.call(submitter)
        end
      end

      if @submission.audit_trail_attachment.blank? && submitters.all?(&:completed_at?)
        @submission.audit_trail_attachment = Submissions::GenerateAuditTrail.call(@submission)
      end

      render json: Submissions::SerializeForApi.call(@submission, submitters, params)
    end

    def create
      Params::SubmissionCreateValidator.call(params)

      return render json: { error: 'Template not found' }, status: :unprocessable_entity if @template.nil?

      if @template.fields.blank?
        Rollbar.warning("Template does not contain fields: #{@template.id}") if defined?(Rollbar)

        return render json: { error: 'Template does not contain fields' }, status: :unprocessable_entity
      end

      params[:send_email] = true unless params.key?(:send_email)
      params[:send_sms] = false unless params.key?(:send_sms)

      submissions = create_submissions(@template, params)

      submissions.each do |submission|
        SendSubmissionCreatedWebhookRequestJob.perform_async({ 'submission_id' => submission.id })
      end

      Submissions.send_signature_requests(submissions)

      submissions.each do |submission|
        if submission.submitters.all?(&:completed_at?) && submission.submitters.last
          ProcessSubmitterCompletionJob.perform_async({ 'submitter_id' => submission.submitters.last.id })
        end
      end

      render json: build_create_json(submissions)
    rescue Submitters::NormalizeValues::BaseError => e
      Rollbar.warning(e) if defined?(Rollbar)

      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      if params[:permanently] == 'true'
        @submission.destroy!
      else
        @submission.update!(archived_at: Time.current)

        SendSubmissionArchivedWebhookRequestJob.perform_async('submission_id' => @submission.id)
      end

      render json: @submission.as_json(only: %i[id archived_at])
    end

    private

    def build_create_json(submissions)
      json = submissions.flat_map do |submission|
        submission.submitters.map do |s|
          Submitters::SerializeForApi.call(s, with_documents: false, with_urls: true, params:)
        end
      end

      json = { submitters: json } if request.path.ends_with?('/init')

      json
    end

    def create_submissions(template, params)
      is_send_email = !params[:send_email].in?(['false', false])

      if (emails = (params[:emails] || params[:email]).presence) &&
         (params[:submission].blank? && params[:submitters].blank?)
        Submissions.create_from_emails(template:,
                                       user: current_user,
                                       source: :api,
                                       mark_as_sent: is_send_email,
                                       emails:,
                                       params:)
      else
        submissions_attrs, attachments =
          Submissions::NormalizeParamUtils.normalize_submissions_params!(submissions_params, template)

        submissions = Submissions.create_from_submitters(
          template:,
          user: current_user,
          source: :api,
          submitters_order: params[:submitters_order] || params[:order] || 'preserved',
          submissions_attrs:,
          params:
        )

        submitters = submissions.flat_map(&:submitters)

        Submissions::NormalizeParamUtils.save_default_value_attachments!(attachments, submitters)

        submitters.each do |submitter|
          SubmissionEvents.create_with_tracking_data(submitter, 'api_complete_form', request) if submitter.completed_at?
        end

        submissions
      end
    end

    def submissions_params
      permitted_attrs = [
        :send_email, :send_sms, :bcc_completed, :completed_redirect_url, :reply_to, :go_to_last,
        {
          message: %i[subject body],
          submitters: [[:send_email, :send_sms, :completed_redirect_url, :uuid, :name, :email, :role,
                        :completed, :phone, :application_key, :external_id, :reply_to, :go_to_last,
                        { metadata: {}, values: {}, readonly_fields: [], message: %i[subject body],
                          fields: [:name, :uuid, :default_value, :value, :title, :description,
                                   :readonly, :redacted, :validation_pattern, :invalid_message,
                                   { default_value: [], value: [], preferences: {} }] }]]
        }
      ]

      if params.key?(:submitters)
        params.permit(*permitted_attrs)
      else
        key = params.key?(:submission) ? :submission : :submissions

        params.permit(
          key => [permitted_attrs]
        ).fetch(key, [])
      end
    end
  end
end
