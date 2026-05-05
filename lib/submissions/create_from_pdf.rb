# frozen_string_literal: true

module Submissions
  module CreateFromPdf
    PDF_CONTENT_TYPE = 'application/pdf'
    BASE64_PDF_REGEXP = %r{\Adata:application/pdf(?:;[^,]+)?;base64,}i
    URL_REGEXP = %r{\Ahttps?://}i

    Error = Class.new(StandardError)

    module_function

    def call(user:, params:)
      template = nil
      attrs = params.to_h.with_indifferent_access

      raise Error, 'documents are required' if attrs[:documents].blank?
      raise Error, 'submitters are required' if attrs[:submitters].blank?
      raise Error, 'template_ids are not supported by this endpoint yet' if attrs[:template_ids].present?

      template = build_template(user, attrs)
      documents_attrs = sorted_documents_attrs(attrs[:documents])
      documents_info = attach_documents(template, documents_attrs, attrs)
      documents = documents_info.pluck(:attachment)

      template.schema = documents.map.with_index do |document, index|
        {
          attachment_uuid: document.uuid,
          name: documents_attrs[index][:name].presence || document.filename.base
        }
      end
      template.submitters = build_template_submitters(attrs)
      template.fields = build_fields(template, documents_info)

      raise Error, 'PDF does not contain fields' if template.fields.blank?

      template.save!

      submissions = Submissions.create_from_submitters(
        template: template,
        user: user,
        source: :api,
        with_template: false,
        submitters_order: attrs[:order] || attrs[:submitters_order] ||
                          Submissions::DEFAULT_SUBMITTERS_ORDER,
        submissions_attrs: [submission_attrs(attrs)]
      )

      submissions.each { |submission| clone_documents_to_submission(template, submission) }

      WebhookUrls.enqueue_events(submissions, 'submission.created')
      Submissions.send_signature_requests(submissions)
      SearchEntries.enqueue_reindex(submissions)

      template.update!(archived_at: Time.current)

      submissions.first
    rescue Templates::CreateAttachments::PdfEncrypted
      raise Error, 'PDF encrypted'
    rescue DownloadUtils::UnableToDownload => e
      raise Error, e.message
    rescue HexaPDF::Error, Pdfium::PdfiumError => e
      raise Error, "Invalid PDF: #{e.message}"
    ensure
      archive_template(template) if template&.persisted? && template.archived_at.blank?
    end

    def build_template(user, attrs)
      Template.create!(
        account: user.account,
        author: user,
        folder: user.account.default_template_folder,
        name: attrs[:name].presence || attrs.dig(:documents, 0, :name).presence || SecureRandom.uuid,
        source: :api,
        fields: [],
        schema: [],
        submitters: []
      )
    end

    def attach_documents(template, documents_attrs, params)
      documents_attrs.map do |document_attrs|
        file, text_tags = build_uploaded_file(document_attrs, remove_tags: remove_tags?(params))
        attachment =
          Templates::CreateAttachments.handle_pdf_or_image(template, file, file.read, params, extract_fields: true)

        text_fields = text_tags.map do |tag|
          field = tag[:field].deep_dup

          field['areas'].each { |area| area['attachment_uuid'] = attachment.uuid }
          field
        end

        { attachment: attachment, text_fields: text_fields, attrs: document_attrs }
      end
    end

    def remove_tags?(params)
      !params[:remove_tags].in?([false, 'false', '0', 0])
    end

    def sorted_documents_attrs(documents_attrs)
      documents_attrs.map(&:with_indifferent_access)
                    .sort_by.with_index { |item, index| item[:position].presence || index }
    end

    def build_uploaded_file(document_attrs, remove_tags: true)
      name = document_attrs[:name].presence || 'document.pdf'
      filename = name.ends_with?('.pdf') ? name : "#{name}.pdf"
      data = read_document_data(document_attrs[:file])
      text_tags = Templates::FindTextTags.call(data)
      data = Templates::RemoveTextTags.call(data, text_tags) if remove_tags

      tempfile = Tempfile.new(['docuseal-submission-pdf', '.pdf'])
      tempfile.binmode
      tempfile.write(data)
      tempfile.rewind

      file = ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: filename,
        type: PDF_CONTENT_TYPE
      )

      [file, text_tags]
    end

    def read_document_data(value)
      raise Error, 'documents[].file is required' if value.blank?

      if value.to_s.match?(URL_REGEXP)
        DownloadUtils.call(value, validate: true).body
      else
        Base64.strict_decode64(value.to_s.sub(BASE64_PDF_REGEXP, ''))
      end
    rescue ArgumentError
      raise Error, 'documents[].file should be a PDF URL or base64 encoded PDF'
    end

    def build_template_submitters(attrs)
      attrs[:submitters].map.with_index do |submitter_attrs, index|
        {
          'name' => submitter_attrs[:role].presence || submitter_attrs[:name].presence ||
                    default_submitter_name(index),
          'uuid' => SecureRandom.uuid,
          'order' => submitter_attrs[:order]
        }.compact
      end
    end

    def default_submitter_name(index)
      name = %w[First Second Third Fourth Fifth Sixth Seventh Eighth Ninth Tenth][index]

      name ? "#{name} Party" : "Party #{index + 1}"
    end

    def build_fields(template, documents_info)
      acro_fields = Templates::ProcessDocument.normalize_attachment_fields(template, documents_info.pluck(:attachment))
      acro_fields_index = acro_fields.group_by { |field| field['areas'].to_a.first&.dig('attachment_uuid') }

      documents_info.flat_map do |info|
        attachment = info[:attachment]
        explicit_fields = Array.wrap(info[:attrs][:fields]).map do |field_attrs|
          build_field(field_attrs.with_indifferent_access, attachment, template)
        end

        if explicit_fields.present?
          explicit_fields
        elsif info[:text_fields].present?
          assign_tag_submitters(info[:text_fields], template)
        else
          acro_fields_index[attachment.uuid].to_a
        end
      end
    end

    def build_field(field_attrs, document, template)
      raise Error, 'fields[].areas are required' if field_attrs[:areas].blank?

      role = field_attrs[:role].presence
      submitter = template.submitters.find { |item| item['name'].to_s.casecmp?(role.to_s) } ||
                  template.submitters.first
      options = build_options(field_attrs[:options])

      {
        'uuid' => field_attrs[:uuid].presence || SecureRandom.uuid,
        'submitter_uuid' => submitter['uuid'],
        'name' => field_attrs[:name].to_s,
        'type' => field_attrs[:type].presence || 'text',
        'required' => field_attrs.key?(:required) ? field_attrs[:required] : true,
        'readonly' => field_attrs[:readonly],
        'title' => field_attrs[:title],
        'description' => field_attrs[:description],
        'preferences' => field_attrs[:preferences] || {},
        'validation' => field_attrs[:validation],
        'options' => options,
        'areas' => Array.wrap(field_attrs[:areas]).map do |area|
          build_area(area.with_indifferent_access, document, options)
        end
      }.compact
    end

    def assign_tag_submitters(fields, template)
      fields.map do |field|
        role = field.delete('role').presence
        submitter = template.submitters.find { |item| item['name'].to_s.casecmp?(role.to_s) } ||
                    template.submitters.first

        field.merge('submitter_uuid' => submitter['uuid'])
      end
    end

    def build_options(options)
      Array.wrap(options).filter_map do |option|
        if option.is_a?(Hash)
          {
            'value' => option[:value] || option['value'],
            'uuid' => option[:uuid] || option['uuid'] || SecureRandom.uuid
          }
        elsif option.present?
          { 'value' => option, 'uuid' => SecureRandom.uuid }
        end
      end.presence
    end

    def build_area(area_attrs, document, options)
      page = area_attrs[:page].to_i
      option = options&.find { |item| item['value'] == area_attrs[:option] }

      {
        'x' => area_attrs[:x].to_f,
        'y' => area_attrs[:y].to_f,
        'w' => area_attrs[:w].to_f,
        'h' => area_attrs[:h].to_f,
        'cell_w' => area_attrs[:cell_w],
        'option_uuid' => area_attrs[:option_uuid] || option&.dig('uuid'),
        'attachment_uuid' => document.uuid,
        'page' => page.positive? ? page - 1 : 0
      }.compact
    end

    def submission_attrs(attrs)
      attrs.slice(:send_email, :send_sms, :bcc_completed, :completed_redirect_url, :reply_to,
                  :expire_at, :name, :message, :variables).merge(
                    submitters: attrs[:submitters]
                  )
    end

    def clone_documents_to_submission(template, submission)
      template.schema_documents.each do |document|
        new_document = submission.documents_attachments.create!(
          uuid: document.uuid,
          blob_id: document.blob_id
        )

        Templates::CloneAttachments.clone_document_preview_images_attachments(
          document: document,
          new_document: new_document
        )
      end
    end

    def archive_template(template)
      template.update_column(:archived_at, Time.current)
    rescue StandardError
      nil
    end
  end
end
