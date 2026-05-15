# frozen_string_literal: true

module Submissions
  module UploadToPaperless
    UploadError = Class.new(StandardError)

    BOUNDARY_PREFIX = '----DocuSealPaperlessUpload'

    module_function

    def call(submission)
      return unless configured?

      submission.submitters.load unless submission.submitters.loaded?

      title = build_title(submission)
      created = completed_date(submission)
      results = documents_to_upload(submission, title).map do |attachment, doc_title|
        upload_document(attachment, title: doc_title, created:)
      end

      results.compact.presence
    end

    def configured?
      ENV['PAPERLESS_NGX_URL'].present? && ENV['PAPERLESS_NGX_TOKEN'].present?
    end

    def documents_to_upload(submission, title)
      documents = []

      if submission.combined_document.attached?
        documents << [submission.combined_document, title]
      else
        submission.submitters.select(&:completed_at?).each do |submitter|
          submitter.documents.each do |doc|
            documents << [doc, title]
          end
        end
      end

      documents << [submission.audit_trail, "#{title} - Audit Trail"] if submission.audit_trail.attached?

      documents
    end

    def build_title(submission)
      submitter_names = submission.submitters
                                  .select(&:completed_at?)
                                  .sort_by(&:completed_at)
                                  .filter_map(&:name)
                                  .join(', ')

      template_name = submission.template&.name || 'Document'

      if submitter_names.present?
        "#{template_name} - #{submitter_names}"
      else
        template_name
      end
    end

    def completed_date(submission)
      last_completed = submission.submitters.filter_map(&:completed_at).max
      last_completed&.strftime('%Y-%m-%d')
    end

    def upload_document(attachment, title:, created:)
      blob = attachment.blob
      filename = sanitize_filename(blob.filename.to_s)
      boundary = "#{BOUNDARY_PREFIX}#{SecureRandom.hex(16)}"

      blob.open do |tempfile|
        body = build_multipart_body(tempfile, filename:, title:, created:, boundary:)

        response = connection.post('/api/documents/post_document/') do |req|
          req.headers['Authorization'] = "Token #{ENV['PAPERLESS_NGX_TOKEN']}" # rubocop:disable Style/FetchEnvVar
          req.headers['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
          req.body = body
          req.options.read_timeout = 30
          req.options.open_timeout = 10
        end

        if response.status >= 400
          body_preview = response.body.to_s.truncate(200)
          raise UploadError, "Paperless-ngx upload failed (HTTP #{response.status}): #{body_preview}"
        end

        response.body.to_s.delete('"').strip
      end
    end

    def sanitize_filename(filename)
      filename.gsub(/["\r\n\\]/, '_')
    end

    def build_multipart_body(tempfile, filename:, title:, created:, boundary:)
      parts = []

      parts << "--#{boundary}\r\n"
      parts << "Content-Disposition: form-data; name=\"document\"; filename=\"#{filename}\"\r\n"
      parts << "Content-Type: application/pdf\r\n\r\n"
      parts << tempfile.read
      parts << "\r\n"

      parts << "--#{boundary}\r\n"
      parts << "Content-Disposition: form-data; name=\"title\"\r\n\r\n"
      parts << title
      parts << "\r\n"

      if created
        parts << "--#{boundary}\r\n"
        parts << "Content-Disposition: form-data; name=\"created\"\r\n\r\n"
        parts << created
        parts << "\r\n"
      end

      parts << "--#{boundary}--\r\n"

      parts.join
    end

    def connection
      Faraday.new(url: ENV['PAPERLESS_NGX_URL']) do |f| # rubocop:disable Style/FetchEnvVar
        f.adapter Faraday.default_adapter
      end
    end
  end
end
