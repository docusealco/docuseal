# frozen_string_literal: true

module Api
  class SubmissionsController < ApiBaseController
    load_and_authorize_resource :template, only: :create
    load_and_authorize_resource :submission, only: %i[show index destroy]

    before_action only: :create do
      authorize!(:create, Submission)
    end

    def index
      submissions = Submissions.search(current_user, @submissions, params[:q])
      submissions = filter_submissions(submissions, params)

      submissions = paginate(submissions.preload(:created_by_user, :submitters,
                                                 template: :folder,
                                                 combined_document_attachment: :blob,
                                                 audit_trail_attachment: :blob))

      render json: {
        data: submissions.map do |s|
          Submissions::SerializeForApi.call(s, s.submitters, params,
                                            with_events: false, with_documents: false, with_values: false)
        end,
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

      WebhookUrls.for_account_id(@template.account_id, 'submission.created').each do |webhook_url|
        submissions.each do |submission|
          SendSubmissionCreatedWebhookRequestJob.perform_async('submission_id' => submission.id,
                                                               'webhook_url_id' => webhook_url.id)
        end
      end

      Submissions.send_signature_requests(submissions)

      submissions.each do |submission|
        submission.submitters.each do |submitter|
          next unless submitter.completed_at?

          ProcessSubmitterCompletionJob.perform_async('submitter_id' => submitter.id, 'send_invitation_email' => false)
        end
      end

      SearchEntries.enqueue_reindex(submissions)

      render json: build_create_json(submissions)
    rescue Submitters::NormalizeValues::BaseError, Submissions::CreateFromSubmitters::BaseError,
           DownloadUtils::UnableToDownload => e
      Rollbar.warning(e) if defined?(Rollbar)

      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      if params[:permanently].in?(['true', true])
        @submission.destroy!
      else
        @submission.update!(archived_at: Time.current)

        WebhookUrls.for_account_id(@submission.account_id, 'submission.archived').each do |webhook_url|
          SendSubmissionArchivedWebhookRequestJob.perform_async('submission_id' => @submission.id,
                                                                'webhook_url_id' => webhook_url.id)
        end
      end

      render json: @submission.as_json(only: %i[id archived_at])
    end

    private

    def filter_submissions(submissions, params)
      submissions = submissions.where(template_id: params[:template_id]) if params[:template_id].present?
      submissions = submissions.where(slug: params[:slug]) if params[:slug].present?

      if params[:template_folder].present?
        folder = TemplateFolder.accessible_by(current_ability).find_by(name: params[:template_folder])

        submissions = folder ? submissions.joins(:template).where(template: { folder_id: folder.id }) : submissions.none
      end

      if params.key?(:archived)
        submissions = params[:archived].in?(['true', true]) ? submissions.archived : submissions.active
      end

      Submissions::Filter.call(submissions, current_user, params)
    end

    def build_create_json(submissions)
      json = submissions.flat_map do |submission|
        submission.submitters.map do |s|
          Submitters::SerializeForApi.call(s, with_documents: false, with_urls: true, params:)
        end
      end

      if request.path.ends_with?('/init')
        json =
          if submissions.size == 1
            {
              id: submissions.first.id,
              submitters: json,
              expire_at: submissions.first.expire_at,
              created_at: submissions.first.created_at
            }
          else
            { submitters: json }
          end
      end

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
        :require_phone_2fa, :expire_at, :name,
        {
          message: %i[subject body],
          submitters: [[:send_email, :send_sms, :completed_redirect_url, :uuid, :name, :email, :role,
                        :completed, :phone, :application_key, :external_id, :reply_to, :go_to_last,
                        :require_phone_2fa,
                        { metadata: {}, values: {}, roles: [], readonly_fields: [], message: %i[subject body],
                          fields: [:name, :uuid, :default_value, :value, :title, :description,
                                   :readonly, :required, :validation_pattern, :invalid_message,
                                   { default_value: [], value: [], preferences: {} }] }]]
        }
      ]

      if params.key?(:submitters)
        params.permit(*permitted_attrs)
      else
        key = params.key?(:submission) ? :submission : :submissions

        params.permit(
          { key => [permitted_attrs] }, { key => permitted_attrs }
        ).fetch(key, [])
      end
    end
  end
end
