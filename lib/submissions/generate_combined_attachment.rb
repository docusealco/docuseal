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

      sign_params = {
        reason: sign_reason,
        **Submissions::GenerateResultAttachments.build_signing_params(pkcs, tsa_url)
      }

      pdf.sign(io, **sign_params)

      Submissions::GenerateResultAttachments.maybe_enable_ltv(io, sign_params)

      ActiveStorage::Attachment.create!(
        blob: ActiveStorage::Blob.create_and_upload!(
          io: io.tap(&:rewind), filename: "#{submission.template.name}.pdf"
        ),
        name: 'combined_document',
        record: submission
      )
    end

    def build_combined_pdf(submitter)
      pdfs_index = Submissions::GenerateResultAttachments.generate_pdfs(submitter)

      audit_trail = Submissions::GenerateAuditTrail.build_audit_trail(submitter.submission)

      audit_trail.dispatch_message(:complete_objects)

      result = HexaPDF::Document.new

      submitter.submission.template_schema.each do |item|
        pdf = pdfs_index[item['attachment_uuid']]

        pdf.dispatch_message(:complete_objects)

        pdf.pages.each { |page| result.pages << result.import(page) }
      end

      audit_trail.pages.each { |page| result.pages << result.import(page) }

      result
    end

    def sign_reason
      'Signed with DocuSeal.co'
    end
  end
end
