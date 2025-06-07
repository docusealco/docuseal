# frozen_string_literal: true

module Submissions
  module GeneratePreviewAttachments
    module_function

    # rubocop:disable Metrics
    def call(submission, values_hash: nil, submitter: nil)
      values_hash ||= if submitter
                        build_submitter_values_hash(submitter)
                      else
                        build_values_hash(submission)
                      end

      configs = submission.account.account_configs.where(key: [AccountConfig::FLATTEN_RESULT_PDF_KEY,
                                                               AccountConfig::WITH_SIGNATURE_ID])

      with_signature_id = configs.find { |c| c.key == AccountConfig::WITH_SIGNATURE_ID }&.value == true
      is_flatten = configs.find { |c| c.key == AccountConfig::FLATTEN_RESULT_PDF_KEY }&.value != false

      pdfs_index = GenerateResultAttachments.build_pdfs_index(submission, flatten: is_flatten)

      submitters = if submitter
                     submission.submitters.where(id: submitter.id)
                   else
                     submission.submitters.where(completed_at: nil)
                   end

      submitters.preload(attachments_attachments: :blob).each_with_index do |s, index|
        GenerateResultAttachments.fill_submitter_fields(s, submission.account, pdfs_index,
                                                        with_signature_id:, is_flatten:, with_headings: index.zero?)
      end

      template = submission.template

      image_pdfs = []
      original_documents = submission.schema_documents.preload(:blob)

      result_attachments =
        (submission.template_schema || template.schema).filter_map do |item|
          pdf = pdfs_index[item['attachment_uuid']]

          next if pdf.nil?

          if original_documents.find { |a| a.uuid == item['attachment_uuid'] }.image?
            pdf = GenerateResultAttachments.normalize_image_pdf(pdf)

            image_pdfs << pdf
          end

          build_pdf_attachment(pdf:, submission:, submitter:,
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
          submitter:,
          uuid: GenerateResultAttachments.images_pdf_uuid(original_documents.select(&:image?)),
          values_hash:,
          name: submission.name || template.name
        )

      ApplicationRecord.no_touching do
        (result_attachments + [images_pdf_attachment]).map { |e| e.tap(&:save!) }
      end
    end

    def build_values_hash(submission)
      Digest::MD5.hexdigest(
        submission.submitters.reduce({}) { |acc, s| acc.merge(s.values) }.to_json
      )
    end

    def build_submitter_values_hash(submitter)
      submission = submitter.submission

      Digest::MD5.hexdigest(
        submission.submitters.where.not(completed_at: nil).or(submission.submitters.where(id: submitter.id))
                  .reduce({}) { |acc, s| acc.merge(s.values) }.to_json
      )
    end

    def build_pdf_attachment(pdf:, submission:, submitter:, uuid:, name:, values_hash:)
      io = StringIO.new

      begin
        pdf.write(io, incremental: true, validate: false)
      rescue HexaPDF::MalformedPDFError => e
        Rollbar.error(e) if defined?(Rollbar)

        pdf.write(io, incremental: false, validate: false)
      end

      ActiveStorage::Attachment.new(
        blob: ActiveStorage::Blob.create_and_upload!(io: io.tap(&:rewind), filename: "#{name}.pdf"),
        io_data: io.string,
        metadata: { original_uuid: uuid,
                    values_hash:,
                    analyzed: true,
                    sha256: Base64.urlsafe_encode64(Digest::SHA256.digest(io.string)) },
        name: 'preview_documents',
        record: submitter || submission
      )
    end
    # rubocop:enable Metrics
  end
end
