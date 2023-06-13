# frozen_string_literal: true

module Submissions
  module GenerateResultAttachments
    FONT_SIZE = 12
    FONT_NAME = 'Helvetica'

    module_function

    # rubocop:disable Metrics
    def call(submitter)
      template = submitter.submission.template

      cert = submitter.submission.template.account.encrypted_configs
                      .find_by(key: EncryptedConfig::ESIGN_CERTS_KEY).value

      zip_file = Tempfile.new
      zip_stream = Zip::ZipOutputStream.open(zip_file)

      pdfs_index = build_pdfs_index(submitter)

      template.fields.each do |field|
        field.fetch('areas', []).each do |area|
          pdf = pdfs_index[area['attachment_uuid']]

          page = pdf.pages[area['page']]

          width = page.box.width
          height = page.box.height

          value = submitter.values[field['uuid']]

          canvas = page.canvas(type: :overlay)

          case field['type']
          when 'image', 'signature'
            attachment = submitter.attachments.find { |a| a.uuid == value }
            io = StringIO.new(attachment.download)

            Vips::Image.new_from_buffer(io.read, '')

            scale = [(area['w'] * width) / attachment.metadata['width'],
                     (area['h'] * height) / attachment.metadata['height']].min

            canvas.image(io, at: [area['x'] * width,
                                  height - (area['y'] * height) -
                                  (((attachment.metadata['height'] * scale) + (area['h'] * height)) / 2)],
                             width: attachment.metadata['width'] * scale,
                             height: attachment.metadata['height'] * scale)
          when 'file'
            Array.wrap(value).each_with_index do |uuid, index|
              attachment = submitter.attachments.find { |a| a.uuid == uuid }

              canvas.image(PdfIcons.paperclip_io,
                           at: [area['x'] * width,
                                height - ((area['y'] * height) + (1.2 * FONT_SIZE) - (FONT_SIZE * index))],
                           width: FONT_SIZE, height: FONT_SIZE)

              canvas.font(FONT_NAME, size: FONT_SIZE)
              canvas.text(attachment.filename.to_s,
                          at: [(area['x'] * width) + FONT_SIZE,
                               height - ((area['y'] * height) + FONT_SIZE - (FONT_SIZE * index))])

              page[:Annots] ||= []
              page[:Annots] << pdf.add({
                                         Type: :Annot, Subtype: :Link,
                                         Rect: [
                                           area['x'] * width,
                                           height - (area['y'] * height),
                                           (area['x'] * width) + (area['w'] * width),
                                           height - (area['y'] * height) - FONT_SIZE
                                         ],
                                         A: { Type: :Action, S: :URI, URI: attachment.url }
                                       })
            end
          when 'checkbox'
            Array.wrap(value).each_with_index do |value, index|
              canvas.image(PdfIcons.check_io,
                           at: [area['x'] * width,
                                height - ((area['y'] * height) + (1.2 * FONT_SIZE) - (FONT_SIZE * index))],
                           width: FONT_SIZE, height: FONT_SIZE)

              canvas.font(FONT_NAME, size: FONT_SIZE)
              canvas.text(value,
                          at: [(area['x'] * width) + FONT_SIZE,
                               height - ((area['y'] * height) + FONT_SIZE - (FONT_SIZE * index))])
            end
          when 'date'
            canvas.font(FONT_NAME, size: FONT_SIZE)
            canvas.text(I18n.l(Date.parse(value)),
                        at: [area['x'] * width, height - ((area['y'] * height) + FONT_SIZE)])
          else
            canvas.font(FONT_NAME, size: FONT_SIZE)
            canvas.text(value.to_s, at: [area['x'] * width, height - ((area['y'] * height) + FONT_SIZE)])
          end
        end
      end

      template.schema.map do |item|
        template.documents.find { |a| a.uuid == item['attachment_uuid'] }

        io = StringIO.new

        pdf = pdfs_index[item['attachment_uuid']]

        pdf.sign(io, reason: "Signed by #{submitter.email}",
                     # doc_mdp_permissions: :no_changes,
                     certificate: OpenSSL::X509::Certificate.new(cert['cert']),
                     key: OpenSSL::PKey::RSA.new(cert['key']),
                     certificate_chain: [OpenSSL::X509::Certificate.new(cert['sub_ca']),
                                         OpenSSL::X509::Certificate.new(cert['root_ca'])])

        zip_stream.put_next_entry("#{item['name']}.pdf")
        zip_stream.write(io.string)

        ActiveStorage::Attachment.create!(
          uuid: item['attachment_uuid'],
          blob: ActiveStorage::Blob.create_and_upload!(
            io: StringIO.new(io.string), filename: "#{item['name']}.pdf"
          ),
          name: 'documents',
          record: submitter
        )
      end

      zip_stream.close

      submitter.archive.attach(io: zip_file, filename: "#{template.name}.zip")
    end
    # rubocop:enable Metrics

    def build_pdfs_index(submitter)
      latest_submitter = submitter.submission.submitters
                                  .select { |e| e.id != submitter.id && e.completed_at? }
                                  .max_by(&:completed_at)

      documents   = latest_submitter&.documents.to_a.presence
      documents ||= submitter.submission.template.documents

      documents.to_h do |attachment|
        [attachment.uuid, HexaPDF::Document.new(io: StringIO.new(attachment.download))]
      end
    end
  end
end
