# frozen_string_literal: true

module Submissions
  module GenerateResultAttachments
    FONT_SIZE = 11
    FONT_NAME = 'Helvetica'

    INFO_CREATOR = "#{Docuseal::PRODUCT_NAME} (#{Docuseal::PRODUCT_URL})".freeze
    SIGN_REASON = 'Signed by %<email>s with docuseal.co'

    TEXT_LEFT_MARGIN = 1
    TEXT_TOP_MARGIN = 1

    A4_SIZE = [595, 842].freeze
    SUPPORTED_IMAGE_TYPES = ['image/png', 'image/jpeg'].freeze

    module_function

    # rubocop:disable Metrics
    def call(submitter)
      layouter = HexaPDF::Layout::TextLayouter.new(valign: :center)
      cell_layouter = HexaPDF::Layout::TextLayouter.new(valign: :center, align: :center)

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

            image_data =
              if SUPPORTED_IMAGE_TYPES.include?(attachment.content_type)
                attachment.download
              else
                Vips::Image.new_from_buffer(attachment.download, '')
                           .write_to_buffer('.png')
              end

            io = StringIO.new(image_data)

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
                    (area['x'] * width) + TEXT_LEFT_MARGIN,
                    height - (area['y'] * height) - lines[...index].sum(&:height) + height_diff,
                    (area['x'] * width) + (area['w'] * width) + TEXT_LEFT_MARGIN,
                    height - (area['y'] * height) - lines[..next_index].sum(&:height) + height_diff
                  ],
                  A: { Type: :Action, S: :URI, URI: attachment.url }
                }
              )

              acc + 1
            end

            layouter.fit(items, area['w'] * width, height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, (area['x'] * width) + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) + height_diff - TEXT_TOP_MARGIN)
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
          when 'cells'
            cell_width = area['cell_w'] * width

            value.chars.each_with_index do |char, index|
              text = HexaPDF::Layout::TextFragment.create(char, font: pdf.fonts.add(FONT_NAME),
                                                                font_size: FONT_SIZE)

              cell_layouter.fit([text], cell_width, area['h'] * height)
                           .draw(canvas, ((area['x'] * width) + (cell_width * index)),
                                 height - (area['y'] * height))
            end
          else
            value = I18n.l(Date.parse(value)) if field['type'] == 'date'

            text = HexaPDF::Layout::TextFragment.create(Array.wrap(value).join(', '), font: pdf.fonts.add(FONT_NAME),
                                                                                      font_size: FONT_SIZE)

            lines = layouter.fit([text], area['w'] * width, height).lines
            box_height = lines.sum(&:height)
            height_diff = [0, box_height - (area['h'] * height)].max

            layouter.fit([text], area['w'] * width, height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, (area['x'] * width) + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) + height_diff - TEXT_TOP_MARGIN)
          end
        end
      end

      image_pdfs = []
      original_documents = template.documents.preload(:blob)

      results =
        template.schema.map do |item|
          pdf = pdfs_index[item['attachment_uuid']]

          attachment = save_signed_pdf(pdf:, submitter:, cert:, uuid: item['attachment_uuid'], name: item['name'])

          image_pdfs << pdf if original_documents.find { |a| a.uuid == item['attachment_uuid'] }.image?

          attachment
        end

      return results if image_pdfs.size < 2

      images_pdf =
        image_pdfs.each_with_object(HexaPDF::Document.new) do |pdf, doc|
          pdf.pages.each { |page| doc.pages << doc.import(page) }
        end

      images_pdf_result =
        save_signed_pdf(
          pdf: images_pdf,
          submitter:,
          cert:,
          uuid: images_pdf_uuid(original_documents.select(&:image?)),
          name: template.name
        )

      results + [images_pdf_result]
    end
    # rubocop:enable Metrics

    def save_signed_pdf(pdf:, submitter:, cert:, uuid:, name:)
      io = StringIO.new

      pdf.trailer.info[:Creator] = INFO_CREATOR

      pdf.sign(io, reason: format(SIGN_REASON, email: submitter.email),
                   certificate: OpenSSL::X509::Certificate.new(cert['cert']),
                   key: OpenSSL::PKey::RSA.new(cert['key']),
                   certificate_chain: [OpenSSL::X509::Certificate.new(cert['sub_ca']),
                                       OpenSSL::X509::Certificate.new(cert['root_ca'])])

      ActiveStorage::Attachment.create!(
        uuid:,
        blob: ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(io.string), filename: "#{name}.pdf"
        ),
        name: 'documents',
        record: submitter
      )
    end

    def images_pdf_uuid(attachments)
      Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, attachments.map(&:uuid).sort.join(':'))
    end

    def build_pdfs_index(submitter)
      latest_submitter = submitter.submission.submitters
                                  .select { |e| e.id != submitter.id && e.completed_at? }
                                  .max_by(&:completed_at)

      documents   = latest_submitter&.documents&.preload(:blob).to_a.presence
      documents ||= submitter.submission.template.documents.preload(:blob)

      documents.to_h do |attachment|
        pdf =
          if attachment.image?
            build_pdf_from_image(attachment)
          else
            HexaPDF::Document.new(io: StringIO.new(attachment.download))
          end

        [attachment.uuid, pdf]
      end
    end

    def build_pdf_from_image(attachment)
      pdf = HexaPDF::Document.new
      page = pdf.pages.add

      scale = [A4_SIZE.first / attachment.metadata['width'].to_f,
               A4_SIZE.last / attachment.metadata['height'].to_f].min

      page.box.width = attachment.metadata['width'] * scale
      page.box.height = attachment.metadata['height'] * scale

      page.canvas.image(
        StringIO.new(attachment.download),
        at: [0, 0],
        width: page.box.width,
        height: page.box.height
      )

      pdf
    end
  end
end
