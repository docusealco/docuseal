# frozen_string_literal: true

module Submitters
  TRUE_VALUES = ['1', 'true', true].freeze
  PRELOAD_ALL_PAGES_AMOUNT = 200

  module_function

  def search(submitters, keyword)
    return submitters if keyword.blank?

    term = "%#{keyword.downcase}%"

    arel_table = Submitter.arel_table

    arel = arel_table[:email].lower.matches(term)
                             .or(arel_table[:phone].matches(term))
                             .or(arel_table[:name].lower.matches(term))

    submitters.where(arel)
  end

  def select_attachments_for_download(submitter)
    if AccountConfig.exists?(account_id: submitter.submission.account_id,
                             key: AccountConfig::COMBINE_PDF_RESULT_KEY,
                             value: true) && submitter.submission.combined_document_attachment
      return [submitter.submission.combined_document_attachment]
    end

    original_documents = submitter.submission.template_schema_documents.preload(:blob)
    is_more_than_two_images = original_documents.count(&:image?) > 1

    submitter.documents.preload(:blob).reject do |attachment|
      is_more_than_two_images &&
        original_documents.find { |a| a.uuid == (attachment.metadata['original_uuid'] || attachment.uuid) }&.image?
    end
  end

  def preload_with_pages(submitter)
    ActiveRecord::Associations::Preloader.new(
      records: [submitter],
      associations: [submission: [:template, { template_schema_documents: :blob }]]
    ).call

    total_pages =
      submitter.submission.template_schema_documents.sum { |e| e.metadata.dig('pdf', 'number_of_pages').to_i }

    if total_pages < PRELOAD_ALL_PAGES_AMOUNT
      ActiveRecord::Associations::Preloader.new(
        records: submitter.submission.template_schema_documents,
        associations: [:blob, { preview_images_attachments: :blob }]
      ).call
    end

    submitter
  end

  def create_attachment!(submitter, params)
    blob =
      if (file = params[:file])
        ActiveStorage::Blob.create_and_upload!(io: file.open,
                                               filename: file.original_filename,
                                               content_type: file.content_type)
      else
        ActiveStorage::Blob.find_signed(params[:blob_signed_id])
      end

    ActiveStorage::Attachment.create!(
      blob:,
      name: params[:name],
      record: submitter
    )
  end

  def normalize_preferences(account, user, params)
    preferences = {}

    message_params = params['message'].presence || params.slice('subject', 'body').presence

    if message_params.present?
      email_message = EmailMessages.find_or_create_for_account_user(account, user,
                                                                    message_params['subject'],
                                                                    message_params['body'])
    end

    preferences['email_message_uuid'] = email_message.uuid if email_message
    preferences['send_email'] = params['send_email'].in?(TRUE_VALUES) if params.key?('send_email')
    preferences['send_sms'] = params['send_sms'].in?(TRUE_VALUES) if params.key?('send_sms')
    preferences['bcc_completed'] = params['bcc_completed'] if params.key?('bcc_completed')
    preferences['reply_to'] = params['reply_to'] if params.key?('reply_to')
    preferences['go_to_last'] = params['go_to_last'] if params.key?('go_to_last')
    preferences['completed_redirect_url'] = params['completed_redirect_url'] if params.key?('completed_redirect_url')

    preferences
  end

  def send_signature_requests(submitters, delay_seconds: nil)
    submitters.each_with_index do |submitter, index|
      next if submitter.email.blank?
      next if submitter.preferences['send_email'] == false

      if delay_seconds
        SendSubmitterInvitationEmailJob.perform_in((delay_seconds + index).seconds, 'submitter_id' => submitter.id)
      else
        SendSubmitterInvitationEmailJob.perform_async('submitter_id' => submitter.id)
      end
    end
  end

  def current_submitter_order?(submitter)
    submitter_items = submitter.submission.template_submitters || submitter.submission.template.submitters

    before_items = submitter_items[0...(submitter_items.find_index { |e| e['uuid'] == submitter.uuid })]

    before_items.reduce(true) do |acc, item|
      acc && submitter.submission.submitters.find { |e| e.uuid == item['uuid'] }&.completed_at?
    end
  end

  def build_document_filename(submitter, blob, filename_format)
    return blob.filename.to_s if filename_format.blank?

    filename = ReplaceEmailVariables.call(filename_format, submitter:)

    filename = filename.gsub('{document.name}', blob.filename.base)
    filename = filename.gsub(' - {submission.status}') do
      if submitter.submission.submitters.all?(&:completed_at?)
        status =
          if submitter.submission.template_fields.any? { |f| f['type'] == 'signature' }
            I18n.t(:signed)
          else
            I18n.t(:completed)
          end

        " - #{status}"
      end
    end

    filename = filename.gsub(
      '{submission.completed_at}',
      I18n.l(submitter.completed_at.in_time_zone(submitter.account.timezone), format: :short)
    )

    "#{filename}.#{blob.filename.extension}"
  end
end
