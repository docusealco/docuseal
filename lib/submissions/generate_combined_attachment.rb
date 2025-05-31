# frozen_string_literal: true

module Submissions
  module GenerateCombinedAttachment
    module_function

    def call(submitter)
      pdf = build_combined_pdf(submitter)

      submission = submitter.submission
      account = submission.account

      pkcs = Accounts.load_signing_pkcs(account)
      tsa_url = Accounts.load_timeserver_url(account)

      io = StringIO.new

      pdf.trailer.info[:Creator] = "#{Docuseal.product_name} (#{Docuseal::PRODUCT_URL})"

      if pkcs
        sign_params = {
          reason: Submissions::GenerateResultAttachments.single_sign_reason(submitter),
          **Submissions::GenerateResultAttachments.build_signing_params(submitter, pkcs, tsa_url)
        }

        sign_pdf(io, pdf, sign_params)

        Submissions::GenerateResultAttachments.maybe_enable_ltv(io, sign_params)
      else
        pdf.write(io, incremental: true, validate: true)
      end

      ActiveStorage::Attachment.create!(
        blob: ActiveStorage::Blob.create_and_upload!(
          io: io.tap(&:rewind), filename: "#{submission.name || submission.template.name}.pdf"
        ),
        name: 'combined_document',
        record: submission
      )
    end

    def sign_pdf(io, pdf, sign_params)
      pdf.sign(io, **sign_params)
    rescue HexaPDF::MalformedPDFError => e
      Rollbar.error(e) if defined?(Rollbar)

      pdf.sign(io, write_options: { incremental: false }, **sign_params)
    rescue HexaPDF::Error => e
      Rollbar.error(e) if defined?(Rollbar)

      pdf.validate(auto_correct: true)

      pdf.sign(io, write_options: { validate: false }, **sign_params)
    end

    def build_combined_pdf(submitter)
      pdfs_index = Submissions::GenerateResultAttachments.generate_pdfs(submitter)

      audit_trail = I18n.with_locale(submitter.account.locale) do
        Submissions::GenerateAuditTrail.build_audit_trail(submitter.submission)
      end

      audit_trail.dispatch_message(:complete_objects)

      result = HexaPDF::Document.new

      submitter.submission.template_schema.each do |item|
        pdf = pdfs_index[item['attachment_uuid']]

        next unless pdf

        pdf.dispatch_message(:complete_objects)

        pdf.pages.each { |page| result.pages << result.import(page) }
      end

      audit_trail.pages.each { |page| result.pages << result.import(page) }

      result
    end
  end
end
