# frozen_string_literal: true

module Submitters
  TRUE_VALUES = ['1', 'true', true].freeze
  PRELOAD_ALL_PAGES_AMOUNT = 200

  FIELD_NAME_WEIGHTS = {
    'email' => 'A',
    'phone' => 'B',
    'name' => 'C',
    'values' => 'D'
  }.freeze

  module_function

  def search(current_user, submitters, keyword)
    if Docuseal.fulltext_search?
      fulltext_search(current_user, submitters, keyword)
    else
      plain_search(submitters, keyword)
    end
  end

  def fulltext_search(current_user, submitters, keyword)
    return submitters if keyword.blank?

    submitters.where(
      id: SearchEntry.where(record_type: 'Submitter')
                     .where(account_id: current_user.account_id)
                     .where(*SearchEntries.build_tsquery(keyword))
                     .select(:record_id)
    )
  end

  def fulltext_search_field(current_user, submitters, keyword, field_name)
    keyword = keyword.delete("\0")

    return submitters.none if keyword.blank?

    weight = FIELD_NAME_WEIGHTS[field_name]

    return submitters.none if weight.blank?

    query =
      if keyword.match?(/\d/) && !keyword.match?(/\p{L}/)
        number = keyword.gsub(/\D/, '')

        sql =
          if number.length <= 2
            "ngram @@ ((quote_literal(?) || ':' || ?)::tsquery || (quote_literal(?) || ':' || ?)::tsquery)"
          else
            "tsvector @@ ((quote_literal(?) || ':*' || ?)::tsquery || (quote_literal(?) || ':*' || ?)::tsquery)"
          end

        [sql, number, weight, number.length > 1 ? number.delete_prefix('0') : number, weight]
      elsif keyword.match?(/[^\p{L}\d&@.\-]/)
        terms = TextUtils.transliterate(keyword.downcase).split(/\b/).map(&:squish).compact_blank.uniq

        if terms.size > 1
          SearchEntries.build_weights_tsquery(terms, weight)
        else
          SearchEntries.build_weights_wildcard_tsquery(keyword, weight)
        end
      else
        SearchEntries.build_weights_wildcard_tsquery(keyword, weight)
      end

    submitter_ids = SearchEntry.where(record_type: 'Submitter')
                               .where(account_id: current_user.account_id)
                               .where(*query)
                               .limit(500)
                               .pluck(:record_id)

    submitters.where(id: submitter_ids.first(100))
  end

  def plain_search(submitters, keyword)
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

    original_documents = submitter.submission.schema_documents.preload(:blob)
    is_more_than_two_images = original_documents.count(&:image?) > 1

    submitter.documents.preload(:blob).reject do |attachment|
      is_more_than_two_images &&
        original_documents.find { |a| a.uuid == (attachment.metadata['original_uuid'] || attachment.uuid) }&.image?
    end
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
    preferences['require_phone_2fa'] = params['require_phone_2fa'].in?(TRUE_VALUES) if params.key?('require_phone_2fa')
    preferences['bcc_completed'] = params['bcc_completed'] if params.key?('bcc_completed')
    preferences['reply_to'] = params['reply_to'] if params.key?('reply_to')
    preferences['go_to_last'] = params['go_to_last'] if params.key?('go_to_last')
    preferences['completed_redirect_url'] = params['completed_redirect_url'] if params.key?('completed_redirect_url')

    preferences
  end

  def send_signature_requests(submitters, delay_seconds: nil)
    submitters.each_with_index do |submitter, index|
      next if submitter.email.blank?
      next if submitter.declined_at?
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
