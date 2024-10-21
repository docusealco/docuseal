# frozen_string_literal: true

module Submissions
  module GeneratePreviewAttachments
    module_function

    # rubocop:disable Metrics
    def call(submission, values_hash: nil)
      values_hash ||= build_values_hash(submission)

      configs = submission.account.account_configs.where(key: [AccountConfig::FLATTEN_RESULT_PDF_KEY,
                                                               AccountConfig::WITH_SIGNATURE_ID])

      with_signature_id = configs.find { |c| c.key == AccountConfig::WITH_SIGNATURE_ID }&.value == true
      is_flatten = configs.find { |c| c.key == AccountConfig::FLATTEN_RESULT_PDF_KEY }&.value != false

      pdfs_index = GenerateResultAttachments.build_pdfs_index(submission, flatten: is_flatten)

      submission.submitters.where(completed_at: nil).preload(attachments_attachments: :blob).each do |submitter|
        GenerateResultAttachments.fill_submitter_fields(submitter, submission.account, pdfs_index,
                                                        with_signature_id:, is_flatten:)
      end

      template = submission.template

      image_pdfs = []
      original_documents = template.documents.preload(:blob)

      result_attachments =
        (submission.template_schema || template.schema).map do |item|
          pdf = pdfs_index[item['attachment_uuid']]

          if original_documents.find { |a| a.uuid == item['attachment_uuid'] }.image?
            pdf = GenerateResultAttachments.normalize_image_pdf(pdf)

            image_pdfs << pdf
          end

          build_pdf_attachment(pdf:, submission:,
                               uuid: item['attachment_uuid'],
                               values_hash:,
                               name: item['name'])
        end

      return ApplicationRecord.no_touching { result_attachments.map { |e| e.tap(&:save!) } } if image_pdfs.size < 2

      images_pdf =
        image_pdfs.each_with_object(HexaPDF::Document.new) do |pdf, doc|
          pdf.pages.each { |page| doc.pages << doc.import(page) }
        end

      images_pdf = GenerateResultAttachments.normalize_image_pdf(images_pdf)

      images_pdf_attachment =
        build_pdf_attachment(
          pdf: images_pdf,
          submission:,
          uuid: GenerateResultAttachments.images_pdf_uuid(original_documents.select(&:image?)),
          values_hash:,
          name: template.name
        )

      ApplicationRecord.no_touching do
        (result_attachments + [images_pdf_attachment]).map { |e| e.tap(&:save!) }
      end
    end

    def build_values_hash(submission)
      submission.submitters.reduce({}) { |acc, s| acc.merge(s.values) }.hash
    end

    def build_pdf_attachment(pdf:, submission:, uuid:, name:, values_hash:)
      io = StringIO.new

      begin
        pdf.write(io, incremental: true, validate: false)
      rescue HexaPDF::MalformedPDFError => e
        Rollbar.error(e) if defined?(Rollbar)

        pdf.write(io, incremental: false, validate: false)
      end

      ActiveStorage::Attachment.new(
        blob: ActiveStorage::Blob.create_and_upload!(io: io.tap(&:rewind), filename: "#{name}.pdf"),
        metadata: { original_uuid: uuid,
                    values_hash:,
                    analyzed: true,
                    sha256: Base64.urlsafe_encode64(Digest::SHA256.digest(io.string)) },
        name: 'preview_documents',
        record: submission
      )
    end
    # rubocop:enable Metrics
  end
end
