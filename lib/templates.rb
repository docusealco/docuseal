# frozen_string_literal: true

module Templates
  COLOR_REGEXP = /\A(#(?:[0-9a-f]{3}|[0-9a-f]{6})|[a-z]+)\z/i

  TEMPLATE_BUILDER_FIELDS = %i[id author_id folder_id external_id name slug
                               schema fields submitters variables_schema preferences
                               shared_link source archived_at created_at updated_at].freeze

  EXPIRATION_DURATIONS = {
    one_day: 1.day,
    two_days: 2.days,
    three_days: 3.days,
    four_days: 4.days,
    five_days: 5.days,
    six_days: 6.days,
    seven_days: 7.days,
    eight_days: 8.days,
    nine_days: 9.days,
    ten_days: 10.days,
    two_weeks: 14.days,
    three_weeks: 21.days,
    four_weeks: 28.days,
    one_month: 1.month,
    two_months: 2.months,
    three_months: 3.months
  }.with_indifferent_access.freeze

  module_function

  def build_field_areas_index(fields)
    hash = {}

    fields.each do |field|
      (field['areas'] || []).each do |area|
        hash[area['attachment_uuid']] ||= {}
        acc = (hash[area['attachment_uuid']][area['page']] ||= [])

        acc << [area, field]
      end
    end

    hash
  end

  def maybe_assign_access(_template)
    nil
  end

  def shared(current_user)
    account = current_user.account

    return Template.none if Docuseal.multitenant? ? !account.testing? : !account.linked_account_account

    shared_account_ids = [current_user.account_id]
    shared_account_ids << TemplateSharing::ALL_ID if !Docuseal.multitenant? && !account.testing?

    exists_access = TemplateAccess.where(TemplateAccess.arel_table[:template_id].eq(Template.arel_table[:id]))
                                  .select(1).arel.exists

    Template.where(id: TemplateSharing.where(account_id: shared_account_ids).select(:template_id))
            .where.not(exists_access)
  end

  def search(current_user, templates, keyword)
    if Docuseal.fulltext_search?
      fulltext_search(current_user, templates, keyword)
    else
      plain_search(templates, keyword)
    end
  end

  def search_shared(current_user, templates, keyword)
    return templates if keyword.blank?

    if Docuseal.fulltext_search?
      templates.where(
        id: SearchEntry.where(record_type: 'Template')
                       .where(account_id: current_user.account.linked_account_account&.account_id)
                       .where(*SearchEntries.build_tsquery(keyword))
                       .select(:record_id)
      )
    else
      plain_search(templates, keyword)
    end
  end

  def plain_search(templates, keyword)
    return templates if keyword.blank?

    sanitized = ActiveRecord::Base.sanitize_sql_like(keyword.downcase)

    templates.where(Template.arel_table[:name].lower.matches("%#{sanitized}%"))
  end

  def fulltext_search(current_user, templates, keyword)
    return templates if keyword.blank?

    templates.where(
      id: SearchEntry.where(record_type: 'Template')
                     .where(account_id: current_user.account_id)
                     .where(*SearchEntries.build_tsquery(keyword))
                     .select(:record_id)
    )
  end

  def filter_undefined_submitters(template_submitters)
    template_submitters.to_a.select do |item|
      item['invite_by_uuid'].blank? && item['optional_invite_by_uuid'].blank? &&
        item['invite_via_field_uuid'].blank? &&
        item['linked_to_uuid'].blank? && item['is_requester'].blank? && item['email'].blank?
    end
  end

  def build_default_expire_at(template)
    default_expire_at_duration = template.preferences['default_expire_at_duration'].presence
    default_expire_at = template.preferences['default_expire_at'].presence

    return if default_expire_at_duration.blank?

    if default_expire_at_duration == 'specified_date' && default_expire_at.present?
      Time.zone.parse(default_expire_at)
    elsif EXPIRATION_DURATIONS[default_expire_at_duration]
      Time.current + EXPIRATION_DURATIONS[default_expire_at_duration]
    end
  end

  def cleanup_document_attachment(attachment)
    return unless attachment.blob.content_type == 'application/pdf'

    io = StringIO.new

    Pdfium::Document.open_bytes(attachment.blob.download) do |doc|
      doc.cleanup
      doc.save(io)
    end

    blob = ActiveStorage::Blob.create_and_upload!(
      io: io.tap(&:rewind),
      filename: attachment.blob.filename.to_s,
      content_type: 'application/pdf'
    )

    attachment.update!(blob_id: blob.id)

    attachment
  end

  def serialize_for_builder(template)
    data = template.as_json(only: TEMPLATE_BUILDER_FIELDS)

    data['documents'] = template.schema_documents.preload(:blob, { preview_images_attachments: :blob }).as_json(
      only: %i[id uuid],
      methods: %i[metadata signed_key],
      include: { preview_images: { only: %i[id], methods: %i[url metadata filename] } }
    )

    data
  end
end
