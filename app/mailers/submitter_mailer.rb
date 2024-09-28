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

    @body = @email_message&.body.presence || @submitter.template.preferences['request_email_body'].presence
    @subject = @email_message&.subject.presence || @submitter.template.preferences['request_email_subject'].presence

    @email_config = AccountConfigs.find_for_account(@current_account, AccountConfig::SUBMITTER_INVITATION_EMAIL_KEY)

    assign_message_metadata('submitter_invitation', @submitter)

    reply_to = build_submitter_reply_to(@submitter)

    I18n.with_locale(@current_account.locale) do
      subject =
        if @email_config || @subject
          ReplaceEmailVariables.call(@subject || @email_config.value['subject'], submitter:)
        elsif @submitter.with_signature_fields?
          I18n.t(:you_are_invited_to_sign_a_document)
        else
          I18n.t(:you_are_invited_to_submit_a_form)
        end

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

    Submissions::EnsureResultGenerated.call(submitter)

    @email_config = AccountConfigs.find_for_account(@current_account, AccountConfig::SUBMITTER_COMPLETED_EMAIL_KEY)

    add_completed_email_attachments!(
      submitter,
      with_documents: @email_config&.value&.dig('attach_documents') != false &&
                      @submitter.template.preferences['completed_notification_email_attach_documents'] != false,
      with_audit_log: @email_config&.value&.dig('attach_audit_log') != false &&
                      @submitter.template.preferences['completed_notification_email_attach_audit'] != false
    )

    @subject = @submitter.template.preferences['completed_notification_email_subject'].presence
    @subject ||= @email_config.value['subject'] if @email_config

    @body = @submitter.template.preferences['completed_notification_email_body'].presence
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
                           name: @submission.template.name.truncate(20),
                           submitter: @submitter.name || @submitter.email || @submitter.phone))
    end
  end

  def documents_copy_email(submitter, to: nil, sig: false)
    @current_account = submitter.submission.account
    @submitter = submitter
    @sig = submitter.signed_id(expires_in: SIGN_TTL, purpose: :download_completed) if sig

    Submissions::EnsureResultGenerated.call(@submitter)

    @email_config = AccountConfigs.find_for_account(@current_account, AccountConfig::SUBMITTER_DOCUMENTS_COPY_EMAIL_KEY)

    @documents = add_completed_email_attachments!(
      submitter, with_audit_log: @submitter.template.preferences['documents_copy_email_attach_audit'] != false &&
                                 (@email_config.nil? || @email_config.value['attach_audit_log'] != false)
    )

    @subject = @submitter.template.preferences['documents_copy_email_subject'].presence
    @subject ||= @email_config.value['subject'] if @email_config

    @body = @submitter.template.preferences['documents_copy_email_body'].presence
    @body ||= @email_config.value['body'] if @email_config

    assign_message_metadata('submitter_documents_copy', @submitter)
    reply_to = build_submitter_reply_to(submitter)

    I18n.with_locale(@current_account.locale) do
      subject =
        if @subject.present?
          ReplaceEmailVariables.call(@subject, submitter:)
        else
          I18n.t(:your_document_copy)
        end

      mail(from: from_address_for_submitter(submitter),
           to: to || @submitter.friendly_name,
           reply_to:,
           subject:)
    end
  end

  private

  def build_submitter_reply_to(submitter)
    reply_to =
      submitter.preferences['reply_to'].presence ||
      (submitter.submission.created_by_user || submitter.template.author)&.friendly_name&.sub(/\+\w+@/, '@')

    return nil if reply_to.to_s.match?(NO_REPLY_REGEXP)

    reply_to
  end

  def add_completed_email_attachments!(submitter, with_audit_log: true, with_documents: true)
    documents = with_documents ? Submitters.select_attachments_for_download(submitter) : []

    total_size = 0
    audit_trail_data = nil

    if with_audit_log && submitter.submission.audit_trail.present? && documents.first&.name != 'combined_document'
      audit_trail_data = submitter.submission.audit_trail.download

      total_size = audit_trail_data.size
    end

    total_size = add_attachments_with_size_limit(documents, total_size)

    attachments[submitter.submission.audit_trail.filename.to_s.tr('"', "'")] = audit_trail_data if audit_trail_data

    if with_documents
      file_fields = submitter.submission.template_fields.select { |e| e['type'].in?(%w[file payment]) }

      if file_fields.pluck('submitter_uuid').uniq.size == 1
        storage_attachments =
          submitter.attachments.where(uuid: submitter.values.values_at(*file_fields.pluck('uuid')).flatten)

        add_attachments_with_size_limit(storage_attachments, total_size)
      end
    end

    documents
  end

  def normalize_user_email(user)
    user.role == 'integration' ? user.friendly_name.sub(/\+\w+@/, '@') : user.friendly_name
  end

  def add_attachments_with_size_limit(storage_attachments, current_size)
    total_size = current_size

    storage_attachments.each do |attachment|
      total_size += attachment.byte_size

      break if total_size >= MAX_ATTACHMENTS_SIZE

      attachments[attachment.filename.to_s.tr('"', "'")] = attachment.download
    end

    total_size
  end

  def from_address_for_submitter(submitter)
    if submitter.submission.source.in?(%w[api embed]) &&
       (from_email = AccountConfig.find_by(account: submitter.account, key: 'integration_from_email')&.value.presence)
      from_email
    else
      (submitter.submission.created_by_user || submitter.submission.template.author).friendly_name
    end
  end
end
