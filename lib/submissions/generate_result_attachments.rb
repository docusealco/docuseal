# frozen_string_literal: true

module Submissions
  module GenerateResultAttachments
    FONT_SIZE = 11
    FONT_NAME = 'Helvetica'

    module_function

    # rubocop:disable Metrics
    def call(submitter)
      layouter = HexaPDF::Layout::TextLayouter.new(valign: :center)
      template = submitter.submission.template

      cert = submitter.submission.template.account.encrypted_configs
                      .find_by(key: EncryptedConfig::ESIGN_CERTS_KEY).value

      pdfs_index = build_pdfs_index(submitter)

      template.fields.each do |field|
        next if field['submitter_uuid'] != submitter.uuid

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

            scale = [(area['w'] * width) / attachment.metadata['width'],
                     (area['h'] * height) / attachment.metadata['height']].min

            canvas.image(
              io,
              at: [
                (area['x'] * width) + (area['w'] * width / 2) - ((attachment.metadata['width'] * scale) / 2),
                height - (area['y'] * height) - (attachment.metadata['height'] * scale / 2) - (area['h'] * height / 2)
              ],
              width: attachment.metadata['width'] * scale,
              height: attachment.metadata['height'] * scale
            )
          when 'file'
            page[:Annots] ||= []

            items = Array.wrap(value).each_with_object([]) do |uuid, acc|
              attachment = submitter.attachments.find { |a| a.uuid == uuid }

              acc << HexaPDF::Layout::InlineBox.create(width: FONT_SIZE, height: FONT_SIZE,
                                                       margin: [0, 1, -2, 0]) do |cv, box|
                cv.image(PdfIcons.paperclip_io, at: [0, 0], width: box.content_width)
              end

              acc << HexaPDF::Layout::TextFragment.create("#{attachment.filename}\n", font: pdf.fonts.add(FONT_NAME),
                                                                                      font_size: FONT_SIZE)
            end

            lines = layouter.fit(items, area['w'] * width, height).lines

            box_height = lines.sum(&:height)
            height_diff = [0, box_height - (area['h'] * height)].max

            lines.each_with_index.reduce(0) do |acc, (line, index)|
              next acc unless line.items.first.is_a?(HexaPDF::Layout::InlineBox)

              attachment_uuid = Array.wrap(value)[acc]
              attachment = submitter.attachments.find { |a| a.uuid == attachment_uuid }

              next_index =
                lines[(index + 1)..].index { |l| l.items.first.is_a?(HexaPDF::Layout::InlineBox) } || (lines.size - 1)

              page[:Annots] << pdf.add(
                {
                  Type: :Annot, Subtype: :Link,
                  Rect: [
                    area['x'] * width,
                    height - (area['y'] * height) - lines[...index].sum(&:height) + height_diff,
                    (area['x'] * width) + (area['w'] * width),
                    height - (area['y'] * height) - lines[..next_index].sum(&:height) + height_diff
                  ],
                  A: { Type: :Action, S: :URI, URI: attachment.url }
                }
              )

              acc + 1
            end

            layouter.fit(items, area['w'] * width, height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, area['x'] * width, height - (area['y'] * height) + height_diff)
          when 'checkbox'
            next unless value == true

            scale = [(area['w'] * width) / PdfIcons::WIDTH, (area['h'] * height) / PdfIcons::HEIGHT].min

            canvas.image(
              PdfIcons.check_io,
              at: [
                (area['x'] * width) + (area['w'] * width / 2) - (PdfIcons::WIDTH * scale / 2),
                height - (area['y'] * height) - (area['h'] * height / 2) - (PdfIcons::HEIGHT * scale / 2)
              ],
              width: PdfIcons::WIDTH * scale,
              height: PdfIcons::HEIGHT * scale
            )
          else
            value = I18n.l(Date.parse(value)) if field['type'] == 'date'

            text = HexaPDF::Layout::TextFragment.create(Array.wrap(value).join(', '), font: pdf.fonts.add(FONT_NAME),
                                                                                      font_size: FONT_SIZE)

            lines = layouter.fit([text], area['w'] * width, height).lines
            box_height = lines.sum(&:height)
            height_diff = [0, box_height - (area['h'] * height)].max

            layouter.fit([text], area['w'] * width, height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, area['x'] * width, height - (area['y'] * height) + height_diff)
          end
        end
      end

      template.schema.map do |item|
        template.documents.find { |a| a.uuid == item['attachment_uuid'] }

        io = StringIO.new

        pdf = pdfs_index[item['attachment_uuid']]

        pdf.sign(io, reason: "Signed by #{submitter.email}",
                     certificate: OpenSSL::X509::Certificate.new(cert['cert']),
                     key: OpenSSL::PKey::RSA.new(cert['key']),
                     certificate_chain: [OpenSSL::X509::Certificate.new(cert['sub_ca']),
                                         OpenSSL::X509::Certificate.new(cert['root_ca'])])

        ActiveStorage::Attachment.create!(
          uuid: item['attachment_uuid'],
          blob: ActiveStorage::Blob.create_and_upload!(
            io: StringIO.new(io.string), filename: "#{item['name']}.pdf"
          ),
          name: 'documents',
          record: submitter
        )
      end
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
