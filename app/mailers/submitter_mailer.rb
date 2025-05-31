# frozen_string_literal: true

class SubmitterMailer < ApplicationMailer
  MAX_ATTACHMENTS_SIZE = 10.megabytes
  SIGN_TTL = 1.hour + 20.minutes

  NO_REPLY_REGEXP = /no-?reply@/i

  def invitation_email(submitter)
    @current_account = submitter.submission.account
    @submitter = submitter

    if submitter.preferences['email_message_uuid']
      @email_message = submitter.account.email_messages.find_by(uuid: submitter.preferences['email_message_uuid'])
    end

    template_submitters_index =
      if @email_message.blank?
        build_submitter_preferences_index(@submitter)
      else
        {}
      end

    @body = @email_message&.body.presence ||
            template_submitters_index.dig(@submitter.uuid, 'request_email_body').presence ||
            @submitter.template&.preferences&.dig('request_email_body').presence

    @subject = @email_message&.subject.presence ||
               template_submitters_index.dig(@submitter.uuid, 'request_email_subject').presence ||
               @submitter.template&.preferences&.dig('request_email_subject').presence

    @email_config = AccountConfigs.find_for_account(@current_account, AccountConfig::SUBMITTER_INVITATION_EMAIL_KEY)

    assign_message_metadata('submitter_invitation', @submitter)

    reply_to = build_submitter_reply_to(@submitter)

    I18n.with_locale(@current_account.locale) do
      subject = build_invite_subject(@subject, @email_config, submitter)

      mail(
        to: @submitter.friendly_name,
        from: from_address_for_submitter(submitter),
        subject:,
        reply_to:
      )
    end
  end

  def completed_email(submitter, user, to: nil)
    @current_account = submitter.submission.account
    @submitter = submitter
    @submission = submitter.submission
    @user = user

    template_preferences = @submission.template&.preferences || {}

    Submissions::EnsureResultGenerated.call(submitter)

    @email_config = AccountConfigs.find_for_account(@current_account, AccountConfig::SUBMITTER_COMPLETED_EMAIL_KEY)

    add_completed_email_attachments!(
      submitter,
      with_documents: @email_config&.value&.dig('attach_documents') != false &&
                      template_preferences['completed_notification_email_attach_documents'] != false,
      with_audit_log: @email_config&.value&.dig('attach_audit_log') != false &&
                      template_preferences['completed_notification_email_attach_audit'] != false
    )

    @subject = template_preferences['completed_notification_email_subject'].presence
    @subject ||= @email_config.value['subject'] if @email_config

    @body = template_preferences['completed_notification_email_body'].presence
    @body ||= @email_config.value['body'] if @email_config

    assign_message_metadata('submitter_completed', @submitter)

    I18n.with_locale(@current_account.locale) do
      subject =
        ReplaceEmailVariables.call(@subject.presence || I18n.t(:template_name_has_been_completed_by_submitters),
                                   submitter:)

      mail(from: from_address_for_submitter(submitter),
           to: to || normalize_user_email(user),
           subject:)
    end
  end

  def declined_email(submitter, user)
    @current_account = submitter.submission.account
    @submitter = submitter
    @submission = submitter.submission
    @user = user

    assign_message_metadata('submitter_declined', @submitter)

    I18n.with_locale(@current_account.locale) do
      mail(from: from_address_for_submitter(submitter),
           to: user.role == 'integration' ? user.friendly_name.sub(/\+\w+@/, '@') : user.friendly_name,
           reply_to: @submitter.friendly_name,
           subject: I18n.t(:name_declined_by_submitter,
                           name: (@submission.name || @submission.template.name).truncate(20),
                           submitter: @submitter.name || @submitter.email || @submitter.phone))
    end
  end

  def documents_copy_email(submitter, to: nil, sig: false)
    @current_account = submitter.submission.account
    @submitter = submitter
    @sig = submitter.signed_id(expires_in: SIGN_TTL, purpose: :download_completed) if sig

    template_preferences = @submitter.template&.preferences || {}

    Submissions::EnsureResultGenerated.call(@submitter)

    @email_config = AccountConfigs.find_for_account(@current_account, AccountConfig::SUBMITTER_DOCUMENTS_COPY_EMAIL_KEY)

    add_completed_email_attachments!(
      submitter,
      with_documents: template_preferences['documents_copy_email_attach_documents'] != false &&
                      (@email_config.nil? || @email_config.value['attach_documents'] != false),
      with_audit_log: template_preferences['documents_copy_email_attach_audit'] != false &&
                      (@email_config.nil? || @email_config.value['attach_audit_log'] != false)
    )

    @subject = template_preferences['documents_copy_email_subject'].presence
    @subject ||= @email_config.value['subject'] if @email_config

    @body = template_preferences['documents_copy_email_body'].presence
    @body ||= @email_config.value['body'] if @email_config

    assign_message_metadata('submitter_documents_copy', @submitter)
    reply_to = build_submitter_reply_to(submitter, email_config: @email_config, documents_copy_email: true)

    I18n.with_locale(@current_account.locale) do
      subject =
        @subject.present? ? ReplaceEmailVariables.call(@subject, submitter:) : I18n.t(:your_document_copy)

      mail(from: from_address_for_submitter(submitter),
           to: to || @submitter.friendly_name,
           reply_to:,
           subject:)
    end
  end

  private

  def build_submitter_reply_to(submitter, email_config: nil, documents_copy_email: nil)
    reply_to = submitter.preferences['reply_to'].presence
    reply_to ||= submitter.template&.preferences&.dig('documents_copy_email_reply_to').presence if documents_copy_email
    reply_to ||= email_config.value['reply_to'].presence if email_config

    if reply_to.blank? && (submitter.submission.created_by_user || submitter.template.author)&.email != submitter.email
      reply_to = (submitter.submission.created_by_user || submitter.template.author)&.friendly_name&.sub(/\+\w+@/, '@')
    end

    return nil if reply_to.to_s.match?(NO_REPLY_REGEXP)

    reply_to
  end

  def add_completed_email_attachments!(submitter, with_audit_log: true, with_documents: true)
    documents = with_documents ? Submitters.select_attachments_for_download(submitter) : []

    filename_format = AccountConfig.find_or_initialize_by(account_id: submitter.account_id,
                                                          key: AccountConfig::DOCUMENT_FILENAME_FORMAT_KEY)&.value

    total_size = 0
    audit_trail_data = nil

    if with_audit_log && submitter.submission.audit_trail.present? && documents.first&.name != 'combined_document'
      audit_trail_data = submitter.submission.audit_trail.download

      total_size = audit_trail_data.size
    end

    total_size = add_attachments_with_size_limit(submitter, documents, total_size, filename_format)

    if audit_trail_data
      audit_trail_filename =
        Submitters.build_document_filename(submitter, submitter.submission.audit_trail.blob, filename_format)

      attachments[audit_trail_filename.tr('"', "'")] = audit_trail_data
    end

    if with_documents
      file_fields = submitter.submission.template_fields.select { |e| e['type'].in?(%w[file payment]) }

      if file_fields.pluck('submitter_uuid').uniq.size == 1
        storage_attachments =
          submitter.attachments.where(uuid: submitter.values.values_at(*file_fields.pluck('uuid')).flatten)

        add_attachments_with_size_limit(submitter, storage_attachments, total_size)
      end
    end

    documents
  end

  def normalize_user_email(user)
    user.role == 'integration' ? user.friendly_name.sub(/\+\w+@/, '@') : user.friendly_name
  end

  def build_invite_subject(subject, email_config, submitter)
    if email_config || subject
      ReplaceEmailVariables.call(subject || email_config.value['subject'], submitter:)
    elsif submitter.with_signature_fields?
      I18n.t(:you_are_invited_to_sign_a_document)
    else
      I18n.t(:you_are_invited_to_submit_a_form)
    end
  end

  def build_submitter_preferences_index(submitter)
    submitter.template&.preferences&.dig('submitters').to_a.index_by { |e| e['uuid'] }
  end

  def add_attachments_with_size_limit(submitter, storage_attachments, current_size, filename_format = nil)
    total_size = current_size

    storage_attachments.each do |attachment|
      total_size += attachment.byte_size

      break if total_size >= MAX_ATTACHMENTS_SIZE

      filename = Submitters.build_document_filename(submitter, attachment.blob, filename_format)
      attachments[filename.to_s.tr('"', "'")] = attachment.download
    end

    total_size
  end

  def from_address_for_submitter(submitter)
    if submitter.submission.source.in?(%w[api embed]) &&
       (from_email = AccountConfig.find_by(account: submitter.account, key: 'integration_from_email')&.value.presence)
      user = submitter.account.users.find_by(email: from_email)

      put_metadata('from_user_id' => user.id)

      from_email
    else
      user = submitter.submission.created_by_user || submitter.submission.template.author

      put_metadata('from_user_id' => user.id)

      user.friendly_name
    end
  end
end
