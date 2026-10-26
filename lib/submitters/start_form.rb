# frozen_string_literal: true

module Submitters
  module StartForm
    COOKIES_TTL = 12.hours
    START_FORM_COOKIES_TTL = 7.days
    RESUBMIT_TTL = 3.days
    COOKIES_DEFAULTS = { httponly: true, secure: Rails.env.production? }.freeze

    NotSaved = Class.new(StandardError)

    module_function

    def can_resubmit?(submitter)
      submitter.completed_at? && submitter.completed_at > RESUBMIT_TTL.ago &&
        %w[api embed mcp].exclude?(submitter.submission.source) &&
        submitter.account.account_configs.find_or_initialize_by(key: AccountConfig::ALLOW_TO_RESUBMIT).value != false
    end

    def can_reopen?(template, submitter, request:, current_user:)
      return false if submitter.submission&.completed_at? && submitter.viewer?
      return true if request.cookie_jar.encrypted[:start_form_slug] == submitter.slug
      return true if request.cookie_jar.encrypted[:email_2fa_slug] == submitter.slug
      return false if submitter.email.blank?
      return true if submitter.completed_at?
      return false if submitter.submission.source_embed?
      return true if template.preferences['shared_link_2fa'] == true
      return false if submitter.submission.source_link?
      return true if current_user && submitter.email == current_user.email &&
                     current_user.account_id == submitter.account_id

      Docuseal.multitenant? || Accounts.can_send_emails?(template.account)
    end

    def assign_start_form_cookie(submitter, request)
      request.cookie_jar.encrypted[:start_form_slug] =
        { value: submitter.slug, expires: START_FORM_COOKIES_TTL.from_now, **COOKIES_DEFAULTS }
    end

    def find_or_initialize_submitter(template, submitter_params, exclude_completed:, request:, current_user: nil)
      required_fields = template.preferences.fetch('link_form_fields', ['email'])

      required_params = required_fields.index_with { |key| submitter_params[key] }

      find_params = required_params.except('name')

      submitter =
        if find_params.compact_blank.blank?
          Submitter.new
        else
          build_submitters_scope(template, exclude_completed:).find_or_initialize_by(find_params)
        end

      if submitter.persisted? && !can_reopen?(template, submitter, request:, current_user:)
        submitter = Submitter.new(find_params)
      end

      submitter.name = required_params['name'] if submitter.new_record?

      submitter
    end

    def build_submitters_scope(template, exclude_completed: false, source: nil)
      submissions = template.submissions.non_expired.active
      submissions = submissions.where(source:) if source

      Submitter
        .where(template_id: template.id)
        .where(submission: submissions)
        .order(id: :desc)
        .where(declined_at: nil)
        .where(external_id: nil)
        .then { |rel| exclude_completed ? rel.where(completed_at: nil) : rel }
    end

    def assign_submission_attributes(submitter, template, ip:, user_agent:, source: :link, resubmit_submitter: nil)
      submitter.assign_attributes(
        uuid: first_submitter_uuid(template),
        ip:,
        ua: user_agent,
        values: resubmit_submitter&.preferences&.fetch('default_values', nil) || {},
        preferences: resubmit_submitter&.preferences.presence || { 'send_email' => true },
        metadata: resubmit_submitter&.metadata.presence || {}
      )

      submitter.assign_attributes(resubmit_submitter.slice(:name, :email, :phone)) if resubmit_submitter

      if submitter.values.present?
        resubmit_submitter.attachments.each do |attachment|
          submitter.attachments << attachment.dup if submitter.values.value?(attachment.uuid)
        end
      end

      submitter.submission ||= Submission.new(template:,
                                              account_id: template.account_id,
                                              template_submitters: template.submitters,
                                              expire_at: Templates.build_default_expire_at(template),
                                              submitters: [submitter],
                                              source:)

      Submissions::CreateFromSubmitters.maybe_set_dynamic_documents(submitter.submission)

      submitter.account_id = submitter.submission.account_id

      submitter
    end

    def first_submitter_uuid(template)
      (Templates.filter_undefined_submitters(template.submitters).first || template.submitters.first)['uuid']
    end

    def verify_2fa_and_save_submitter(submitter, request, is_new_record:)
      is_otp_verified = Submitters.verify_link_otp!(request.params[:one_time_code], submitter)

      return false if !is_otp_verified && request.cookie_jar.encrypted[:email_2fa_slug] != submitter.slug

      raise NotSaved unless submitter.save

      enqueue_new_submitter_jobs(submitter) if is_new_record

      assign_start_form_cookie(submitter, request)

      if is_otp_verified
        SubmissionEvents.create_with_tracking_data(submitter, 'email_verified', request)

        request.cookie_jar.encrypted[:email_2fa_slug] =
          { value: submitter.slug, expires: COOKIES_TTL.from_now, **COOKIES_DEFAULTS }
      end

      true
    end

    def enqueue_new_submitter_jobs(submitter)
      WebhookUrls.enqueue_events(submitter.submission, 'submission.created')

      SearchEntries.enqueue_reindex(submitter)

      expire_at = submitter.submission.expire_at

      return unless expire_at

      ProcessSubmissionExpiredJob.perform_at(expire_at, 'submission_id' => submitter.submission_id,
                                                        'expire_at' => expire_at.to_i)
    end
  end
end
