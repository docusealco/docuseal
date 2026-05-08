# frozen_string_literal: true

module Embed
  class FormsController < ActionController::API
    include ActionController::Cookies
    include ActiveStorage::SetCurrent
    include EmbedCors

    before_action :set_embed_cors_headers, only: :preflight

    def create
      slug = token_payload['slug'] || params[:slug].presence || params[:template_slug].presence

      raise ActiveRecord::RecordNotFound if slug.blank?

      submitter = Submitter.find_by(slug: slug)

      payload =
        if submitter
          @embed_cors_account = submitter.account

          form_json(submitter)
        else
          template = Template.find_by!(slug: slug)
          @embed_cors_account = template.account

          form_json_for_template(template)
        end

      set_embed_cors_headers

      render json: payload, status: payload[:error].present? ? :unprocessable_content : :ok
    end

    def preflight
      head :ok
    end

    private

    def form_json_for_template(template)
      validate_shared_link_template!(template)

      attrs = submitter_params

      return { template: template_json(template), logo: logo_json(template.account) } if attrs.compact_blank.blank?

      submitter = find_or_initialize_submitter(template, attrs)

      return shared_link_multiple_parties_error if multiple_parties_shared_link?(template, submitter)

      prepare_shared_link_submitter(submitter, template)
      assign_shared_link_params(submitter)

      if shared_link_2fa_required?(template, submitter)
        Submitters.send_shared_link_email_verification_code(submitter, request: request)

        return unverified_shared_link_email_json(template, submitter)
      end

      save_shared_link_submitter(submitter)
    end

    def form_json(submitter)
      raise ActiveRecord::RecordNotFound if submitter.account.archived_at?

      unavailable_payload = unavailable_submitter_json(submitter)

      return unavailable_payload if unavailable_payload

      pending_payload = pending_verification_json(submitter)

      return pending_payload if pending_payload

      ready_submitter_json(submitter)
    end

    def ready_submitter_json(submitter)
      submission = submitter.submission

      Submissions.preload_with_pages(submission)
      Submitters::MaybeUpdateDefaultValues.call(submitter, nil)

      {
        template: template_json(submitter.template),
        submission: submission_json(submission, submitter),
        submitter: submitter_json(submitter),
        documents: documents_json(submission),
        attachments: attachments_json(submission),
        values: values_param.presence || {},
        logo: logo_json(submitter.account)
      }
    end

    def unavailable_submitter_json(submitter)
      return submitter_status_json(submitter, :expired_submitter) if submitter.submission.expired?
      return submitter_status_json(submitter, :completed_submitter) if submitter.completed_at?

      submitter_status_json(submitter, :expired_submitter) if submitter.declined_at?
    end

    def submitter_status_json(submitter, key)
      {
        key => submitter_json(submitter),
        submission: submission_json(submitter.submission, submitter),
        template: template_json(submitter.template),
        logo: logo_json(submitter.account)
      }
    end

    def pending_verification_json(submitter)
      unless Submitters::AuthorizedForForm.pass_email_2fa?(submitter, request)
        return submitter_status_json(submitter, :submitter_email_2fa)
      end

      return if Submitters::AuthorizedForForm.pass_link_2fa?(submitter, nil, request)

      {
        unverified_email: submitter.email,
        submission: submission_json(submitter.submission, submitter),
        template: template_json(submitter.template),
        logo: logo_json(submitter.account)
      }
    end

    def validate_shared_link_template!(template)
      raise ActiveRecord::RecordNotFound if template.archived_at? || template.account.archived_at?
      raise ActiveRecord::RecordNotFound unless template.shared_link?
    end

    def multiple_parties_shared_link?(template, submitter)
      selected_template_submitter(template).blank? &&
        filter_undefined_submitters(template).size > 1 &&
        submitter.new_record?
    end

    def shared_link_multiple_parties_error
      { error: I18n.t('this_template_has_multiple_parties_which_prevents_the_use_of_a_sharing_link') }
    end

    def prepare_shared_link_submitter(submitter, template)
      if submitter.new_record?
        assign_submission_attributes(submitter, template)
        Submissions::AssignDefinedSubmitters.call(submitter.submission)
      else
        submitter.assign_attributes(ip: request.remote_ip, ua: request.user_agent)
      end
    end

    def assign_shared_link_params(submitter)
      submitter.values = values_param.presence || submitter.values
      submitter.metadata = metadata_param.presence || submitter.metadata
      submitter.external_id = params[:external_id].presence || submitter.external_id
    end

    def shared_link_2fa_required?(template, submitter)
      template.preferences['shared_link_2fa'] == true &&
        !Submitters::AuthorizedForForm.pass_link_2fa?(submitter, nil, request)
    end

    def unverified_shared_link_email_json(template, submitter)
      {
        template: template_json(template),
        unverified_email: submitter.email,
        logo: logo_json(template.account)
      }
    end

    def save_shared_link_submitter(submitter)
      if submitter.errors.blank? && submitter.save
        enqueue_new_submitter_jobs(submitter) if submitter.previous_changes.key?('id')

        form_json(submitter)
      else
        { error: submitter.errors.full_messages.to_sentence }
      end
    end

    def template_json(template)
      template.as_json(only: %i[id name slug preferences schema submitters archived_at account_id])
    end

    def submission_json(submission, submitter = nil)
      submission.as_json(
        only: %i[
          id slug name source submitters_order expire_at archived_at created_at updated_at template_id account_id
        ],
        methods: %i[expired?]
      ).merge(
        'template_schema' => Submissions.filtered_conditions_schema(submission,
                                                                    include_submitter_uuid: submitter&.uuid),
        'template_fields' => submission.template_fields || submission.template.fields,
        'template_submitters' => submission.template_submitters || submission.template.submitters,
        'submitters' => submission.submitters.as_json(
          only: %i[id uuid slug name email phone completed_at declined_at opened_at sent_at]
        )
      )
    end

    def submitter_json(submitter)
      submitter.as_json(
        only: %i[id uuid slug name email phone values metadata preferences completed_at declined_at opened_at sent_at]
      )
    end

    def documents_json(submission)
      submission.schema_documents.as_json(
        methods: %i[metadata signed_key],
        include: { preview_images: { methods: %i[url metadata filename] } }
      )
    end

    def attachments_json(submission)
      ActiveStorage::Attachment.where(record: submission.submitters, name: :attachments)
                               .preload(:blob)
                               .as_json(only: %i[uuid created_at], methods: %i[url filename content_type])
    end

    def logo_json(account)
      return unless account.logo.attached?

      { url: account.logo.url }
    end

    def find_or_initialize_submitter(template, attrs)
      required_fields = template.preferences.fetch('link_form_fields', ['email'])
      required_params = required_fields.index_with { |key| attrs[key] }
      find_params = required_params.except('name')

      submitter = Submitter.new if find_params.compact_blank.blank?

      relation =
        Submitter
        .where(submission: template.submissions.where(expire_at: Time.current..)
                                   .or(template.submissions.where(expire_at: nil)).where(archived_at: nil))
        .order(id: :desc)
        .where(declined_at: nil)
        .where(external_id: nil)
        .where(template.preferences['shared_link_2fa'] == true ? {} : { ip: [nil, request.remote_ip] })

      if (template_submitter = selected_template_submitter(template))
        relation = relation.where(uuid: template_submitter['uuid'])
      end

      submitter ||= relation
        .find_or_initialize_by(find_params)

      submitter.name = required_params['name'] if submitter.new_record?

      required_params.each do |key, value|
        submitter.errors.add(key.to_sym, :blank) if value.blank?
      end

      submitter
    end

    def assign_submission_attributes(submitter, template)
      submitter.assign_attributes(
        uuid: (selected_template_submitter(template) || filter_undefined_submitters(template).first ||
               template.submitters.first)['uuid'],
        ip: request.remote_ip,
        ua: request.user_agent,
        values: {},
        preferences: { 'send_email' => params[:send_email] },
        metadata: {}
      )

      submitter.submission ||= Submission.new(template: template,
                                              account_id: template.account_id,
                                              template_submitters: template.submitters,
                                              template_fields: template.fields,
                                              template_schema: template.schema,
                                              expire_at: Templates.build_default_expire_at(template),
                                              submitters: [submitter],
                                              source: :embed)

      Submissions::CreateFromSubmitters.maybe_set_dynamic_documents(submitter.submission)

      submitter.account_id = submitter.submission.account_id
    end

    def enqueue_new_submitter_jobs(submitter)
      WebhookUrls.enqueue_events(submitter.submission, 'submission.created')
      SearchEntries.enqueue_reindex(submitter)

      return unless submitter.submission.expire_at?

      ProcessSubmissionExpiredJob.perform_at(submitter.submission.expire_at, 'submission_id' => submitter.submission_id)
    end

    def filter_undefined_submitters(template)
      Templates.filter_undefined_submitters(template.submitters)
    end

    def selected_template_submitter(template)
      submitter_name = params[:submitter].presence || params[:role].presence

      return if submitter_name.blank?

      template.submitters.find { |item| item['uuid'] == submitter_name || item['name'] == submitter_name }
    end

    def submitter_params
      {
        'email' => Submissions.normalize_email(params[:email].presence),
        'name' => params[:name].presence,
        'phone' => params[:phone].presence
      }.compact
    end

    def values_param
      params[:values].respond_to?(:to_unsafe_h) ? params[:values].to_unsafe_h : params[:values]
    end

    def metadata_param
      params[:metadata].respond_to?(:to_unsafe_h) ? params[:metadata].to_unsafe_h : params[:metadata]
    end

    def token_payload
      return {} if params[:token].blank?

      JSON.parse(Base64.urlsafe_decode64(params[:token].split('.')[1])).with_indifferent_access
    rescue JSON::ParserError, ArgumentError
      {}
    end
  end
end
