# frozen_string_literal: true

module Submissions
  module GenerateResultAttachments
    FONT_SIZE = 11
    FONT_PATH = '/fonts/LiberationSans-Regular.ttf'
    FONT_NAME = if File.exist?(FONT_PATH)
                  FONT_PATH
                else
                  'Helvetica'
                end

    SIGN_REASON = 'Signed by %<name>s with DocuSeal.co'
    SIGN_SIGNLE_REASON = 'Digitally signed with DocuSeal.co'

    RTL_REGEXP = /\A[\p{Hebrew}\p{Arabic}].*[\p{Hebrew}\p{Arabic}]\z/

    TEXT_LEFT_MARGIN = 1
    TEXT_TOP_MARGIN = 1

    A4_SIZE = [595, 842].freeze
    SUPPORTED_IMAGE_TYPES = ['image/png', 'image/jpeg'].freeze

    module_function

    # rubocop:disable Metrics
    def call(submitter)
      cell_layouter = HexaPDF::Layout::TextLayouter.new(valign: :center, align: :center)

      template = submitter.submission.template

      account = submitter.submission.template.account
      pkcs = Accounts.load_signing_pkcs(account)
      tsa_url = Accounts.load_timeserver_url(account)

      pdfs_index = build_pdfs_index(submitter)

      submitter.submission.template_fields.each do |field|
        next if field['submitter_uuid'] != submitter.uuid

        field.fetch('areas', []).each do |area|
          pdf = pdfs_index[area['attachment_uuid']]

          next if pdf.nil?

          page = pdf.pages[area['page']]

          next if page.nil?

          page.rotate(0, flatten: true) if page[:Rotate] != 0

          page[:Annots] ||= []
          page[:Annots] = page[:Annots].reject do |e|
            e.present? && e[:A] && e[:A][:URI].to_s.starts_with?('file:///docuseal_field')
          end

          width = page.box.width
          height = page.box.height
          font_size = ((page.box.width / A4_SIZE[0].to_f) * FONT_SIZE).to_i

          value = submitter.values[field['uuid']]

          layouter = HexaPDF::Layout::TextLayouter.new(valign: :center,
                                                       align: value.to_s.match?(RTL_REGEXP) ? :right : :left,
                                                       font: pdf.fonts.add(FONT_NAME), font_size:)

          next if Array.wrap(value).compact_blank.blank?

          canvas = page.canvas(type: :overlay)
          canvas.font(FONT_NAME, size: font_size)

          case field['type']
          when 'image', 'signature', 'initials', 'stamp'
            attachment = submitter.attachments.find { |a| a.uuid == value }

            image = Vips::Image.new_from_buffer(attachment.download, '').autorot

            scale = [(area['w'] * width) / image.width,
                     (area['h'] * height) / image.height].min

            io = StringIO.new(image.resize([scale * 4, 1].select(&:positive?).min).write_to_buffer('.png'))

            canvas.image(
              io,
              at: [
                (area['x'] * width) + (area['w'] * width / 2) - ((image.width * scale) / 2),
                height - (area['y'] * height) - (image.height * scale / 2) - (area['h'] * height / 2)
              ],
              width: image.width * scale,
              height: image.height * scale
            )
          when 'file', 'payment'
            items = Array.wrap(value).each_with_object([]) do |uuid, acc|
              attachment = submitter.attachments.find { |a| a.uuid == uuid }

              acc << HexaPDF::Layout::InlineBox.create(width: font_size, height: font_size,
                                                       margin: [0, 1, -2, 0]) do |cv, box|
                cv.image(PdfIcons.paperclip_io, at: [0, 0], width: box.content_width)
              end

              acc << HexaPDF::Layout::TextFragment.create("#{attachment.filename}\n", font: pdf.fonts.add(FONT_NAME),
                                                                                      font_size:)
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
                  A: { Type: :Action, S: :URI,
                       URI: h.rails_blob_url(attachment, **Docuseal.default_url_options) }
                }
              )

              acc + 1
            end

            layouter.fit(items, area['w'] * width, height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, (area['x'] * width) + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) + height_diff - TEXT_TOP_MARGIN)
          when ->(type) { type == 'checkbox' || (type.in?(%w[multiple radio]) && area['option_uuid'].present?) }
            if field['type'].in?(%w[multiple radio])
              option = field['options']&.find { |o| o['uuid'] == area['option_uuid'] }

              value = Array.wrap(value).include?(option['value'])
            end

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

            maybe_rtl_reverse(value).chars.each_with_index do |char, index|
              text = HexaPDF::Layout::TextFragment.create(char, font: pdf.fonts.add(FONT_NAME),
                                                                font_size:)

              cell_layouter.fit([text], cell_width, area['h'] * height)
                           .draw(canvas, ((area['x'] * width) + (cell_width * index)),
                                 height - (area['y'] * height))
            end
          else
            if field['type'] == 'date'
              value = TimeUtils.format_date_string(value, field.dig('preferences', 'format'), account.locale)
            end

            value = maybe_rtl_reverse(Array.wrap(value).join(', '))

            text = HexaPDF::Layout::TextFragment.create(value, font: pdf.fonts.add(FONT_NAME),
                                                               font_size:)

            lines = layouter.fit([text], area['w'] * width, height).lines
            box_height = lines.sum(&:height)

            if box_height > (area['h'] * height) + 1
              text = HexaPDF::Layout::TextFragment.create(value,
                                                          font: pdf.fonts.add(FONT_NAME),
                                                          font_size: (font_size / 1.4).to_i)

              lines = layouter.fit([text], area['w'] * width, height).lines

              box_height = lines.sum(&:height)
            end

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
        submitter.submission.template_schema.map do |item|
          pdf = pdfs_index[item['attachment_uuid']]

          attachment = save_pdf(pdf:, submitter:, pkcs:, tsa_url:,
                                uuid: item['attachment_uuid'],
                                name: item['name'])

          image_pdfs << pdf if original_documents.find { |a| a.uuid == item['attachment_uuid'] }.image?

          attachment
        end

      return results if image_pdfs.size < 2

      images_pdf =
        image_pdfs.each_with_object(HexaPDF::Document.new) do |pdf, doc|
          pdf.pages.each { |page| doc.pages << doc.import(page) }
        end

      images_pdf_result =
        save_pdf(
          pdf: images_pdf,
          submitter:,
          tsa_url:,
          pkcs:,
          uuid: images_pdf_uuid(original_documents.select(&:image?)),
          name: template.name
        )

      results + [images_pdf_result]
    end
    # rubocop:enable Metrics

    def save_pdf(pdf:, submitter:, pkcs:, tsa_url:, uuid:, name:)
      io = StringIO.new

      pdf.trailer.info[:Creator] = info_creator

      sign_reason = fetch_sign_reason(submitter)

      if sign_reason
        sign_params = {
          reason: sign_reason,
          certificate: pkcs.certificate,
          key: pkcs.key,
          certificate_chain: pkcs.ca_certs || []
        }

        if tsa_url
          sign_params[:timestamp_handler] = Submissions::TimestampHandler.new(tsa_url:)
          sign_params[:signature_size] = 10_000
        end

        pdf.sign(io, write_options: { validate: false }, **sign_params)
      else
        pdf.write(io, incremental: true, validate: false)
      end

      ActiveStorage::Attachment.create!(
        uuid:,
        blob: ActiveStorage::Blob.create_and_upload!(io: StringIO.new(io.string), filename: "#{name}.pdf"),
        metadata: { sha256: Base64.urlsafe_encode64(Digest::SHA256.digest(io.string)) },
        name: 'documents',
        record: submitter
      )
    end

    def images_pdf_uuid(attachments)
      Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, attachments.map(&:uuid).sort.join(':'))
    end

    def build_pdfs_index(submitter)
      latest_submitter =
        submitter.submission.submitters
                 .select(&:completed_at?)
                 .select { |e| e.id != submitter.id && e.completed_at <= submitter.completed_at }
                 .max_by(&:completed_at)

      Submissions::EnsureResultGenerated.call(latest_submitter) if latest_submitter

      documents   = latest_submitter&.documents&.preload(:blob).to_a.presence
      documents ||= submitter.submission.template_schema_documents.preload(:blob)

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
        StringIO.new(attachment.preview_images.first.download),
        at: [0, 0],
        width: page.box.width,
        height: page.box.height
      )

      pdf
    end

    def maybe_rtl_reverse(text)
      if text.match?(RTL_REGEXP)
        text.reverse
      else
        text
      end
    end

    def sign_reason(name)
      format(SIGN_REASON, name:)
    end

    def single_sign_reason
      SIGN_SIGNLE_REASON
    end

    def fetch_sign_reason(submitter)
      reason_name = submitter.email || submitter.name || submitter.phone

      return sign_reason(reason_name) if Docuseal.multitenant?

      config =
        if Docuseal.multitenant?
          AccountConfig.where(account: submitter.account, key: AccountConfig::ESIGNING_PREFERENCE_KEY)
                       .first_or_initialize(value: 'multiple')
        else
          AccountConfig.where(key: AccountConfig::ESIGNING_PREFERENCE_KEY)
                       .first_or_initialize(value: 'multiple')
        end

      return sign_reason(reason_name) if config.value == 'multiple'

      return single_sign_reason if !submitter.submission.submitters.exists?(completed_at: nil) &&
                                   submitter.completed_at == submitter.submission.submitters.maximum(:completed_at)

      nil
    end

    def info_creator
      "#{Docuseal.product_name} (#{Docuseal::PRODUCT_URL})"
    end

    def h
      Rails.application.routes.url_helpers
    end
  end
end
