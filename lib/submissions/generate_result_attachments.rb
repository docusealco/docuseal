# frozen_string_literal: true

module Submissions
  module GenerateResultAttachments
    FONT_SIZE = 11
    FONT_PATH = '/fonts/GoNotoKurrent-Regular.ttf'
    FONT_NAME = if File.exist?(FONT_PATH)
                  FONT_PATH
                else
                  'Helvetica'
                end

    SIGN_REASON = 'Signed by %<name>s with DocuSeal.co'

    RTL_REGEXP = TextUtils::RTL_REGEXP

    TEXT_LEFT_MARGIN = 1
    TEXT_TOP_MARGIN = 1
    MAX_PAGE_ROTATE = 20

    A4_SIZE = [595, 842].freeze
    SUPPORTED_IMAGE_TYPES = ['image/png', 'image/jpeg'].freeze

    MISSING_GLYPH_REPLACE = {
      '▪' => '-',
      '✔️' => 'V',
      '✔' => 'V',
      '✅' => 'V'
    }.freeze

    MISSING_GLYPH_REPLACE_TYPE1 = {
      '▪' => :bullet,
      '✔️' => :V,
      '✔' => :V,
      '✅' => :V
    }.freeze

    module_function

    # rubocop:disable Metrics
    def call(submitter)
      pdfs_index = generate_pdfs(submitter)

      template = submitter.submission.template
      account = submitter.account

      pkcs = Accounts.load_signing_pkcs(account)
      tsa_url = Accounts.load_timeserver_url(account)

      image_pdfs = []
      original_documents = template.documents.preload(:blob)

      result_attachments =
        submitter.submission.template_schema.map do |item|
          pdf = pdfs_index[item['attachment_uuid']]

          attachment = build_pdf_attachment(pdf:, submitter:, pkcs:, tsa_url:,
                                            uuid: item['attachment_uuid'],
                                            name: item['name'])

          image_pdfs << pdf if original_documents.find { |a| a.uuid == item['attachment_uuid'] }.image?

          attachment
        end

      return result_attachments.map { |e| e.tap(&:save!) } if image_pdfs.size < 2

      images_pdf =
        image_pdfs.each_with_object(HexaPDF::Document.new) do |pdf, doc|
          pdf.pages.each { |page| doc.pages << doc.import(page) }
        end

      images_pdf_attachment =
        build_pdf_attachment(
          pdf: images_pdf,
          submitter:,
          tsa_url:,
          pkcs:,
          uuid: images_pdf_uuid(original_documents.select(&:image?)),
          name: template.name
        )

      (result_attachments + [images_pdf_attachment]).map { |e| e.tap(&:save!) }
    end

    def generate_pdfs(submitter)
      cell_layouter = HexaPDF::Layout::TextLayouter.new(text_valign: :center, text_align: :center)

      is_flatten =
        submitter.account.account_configs
                 .find_or_initialize_by(key: AccountConfig::FLATTEN_RESULT_PDF_KEY).value != false

      account = submitter.account
      attachments_data_cache = {}

      pdfs_index = build_pdfs_index(submitter, flatten: is_flatten)

      submitter.submission.template_fields.each do |field|
        next if field['submitter_uuid'] != submitter.uuid

        field.fetch('areas', []).each do |area|
          pdf = pdfs_index[area['attachment_uuid']]

          next if pdf.nil?

          page = pdf.pages[area['page']]

          next if page.nil?

          page.rotate(0, flatten: true) if page[:Rotate] != 0

          page[:Annots] ||= []
          page[:Annots] = page[:Annots].try(:reject) do |e|
            next if e.is_a?(Integer)

            e.present? && e[:A] && e[:A][:URI].to_s.starts_with?('file:///docuseal_field')
          end || page[:Annots]

          width = page.box.width
          height = page.box.height
          font_size = (([page.box.width, page.box.height].min / A4_SIZE[0].to_f) * FONT_SIZE).to_i

          value = submitter.values[field['uuid']]

          text_align = field.dig('preferences', 'align').to_s.to_sym.presence ||
                       (value.to_s.match?(RTL_REGEXP) ? :right : :left)

          layouter = HexaPDF::Layout::TextLayouter.new(text_valign: :center, text_align:,
                                                       font: pdf.fonts.add(FONT_NAME), font_size:)

          next if Array.wrap(value).compact_blank.blank?

          if is_flatten
            begin
              page.flatten_annotations
            rescue StandardError => e
              Rollbar.error(e) if defined?(Rollbar)
            end
          end

          canvas = page.canvas(type: :overlay)
          canvas.font(FONT_NAME, size: font_size)

          case field['type']
          when 'image', 'signature', 'initials', 'stamp'
            attachment = submitter.attachments.find { |a| a.uuid == value }

            attachments_data_cache[attachment.uuid] ||= attachment.download

            image = Vips::Image.new_from_buffer(attachments_data_cache[attachment.uuid], '').autorot

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

              next_index = lines[(index + 1)..].index { |l| l.items.first.is_a?(HexaPDF::Layout::InlineBox) }
              next_index += index if next_index
              next_index ||= lines.size - 1

              diff = ((area['h'] * height) / 2) - (lines.sum(&:height) / 2)

              page[:Annots] << pdf.add(
                {
                  Type: :Annot, Subtype: :Link,
                  Rect: [
                    (area['x'] * width) + TEXT_LEFT_MARGIN,
                    height - (area['y'] * height) - lines[...index].sum(&:height) +
                    height_diff - (height_diff.zero? ? diff : 0),
                    (area['x'] * width) + (area['w'] * width) + TEXT_LEFT_MARGIN,
                    height - (area['y'] * height) - lines[..next_index].sum(&:height) +
                    height_diff - (height_diff.zero? ? diff : 0)
                  ],
                  A: { Type: :Action, S: :URI,
                       URI: ActiveStorage::Blob.proxy_url(attachment.blob) }
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

              option_name = option['value'].presence || "Option #{field['options'].index(option) + 1}"

              value = Array.wrap(value).include?(option_name)
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
          when ->(type) { type == 'cells' && area['cell_w'] }
            cell_width = area['cell_w'] * width

            TextUtils.maybe_rtl_reverse(value).chars.each_with_index do |char, index|
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

            value = NumberUtils.format_number(value, field.dig('preferences', 'format')) if field['type'] == 'number'

            value = TextUtils.maybe_rtl_reverse(Array.wrap(value).join(', '))

            text = HexaPDF::Layout::TextFragment.create(value, font: pdf.fonts.add(FONT_NAME),
                                                               font_size:)

            lines = layouter.fit([text], area['w'] * width, height).lines
            box_height = lines.sum(&:height)

            if box_height > (area['h'] * height) + 1
              text = HexaPDF::Layout::TextFragment.create(value,
                                                          font: pdf.fonts.add(FONT_NAME),
                                                          font_size: (font_size / 1.4).to_i)

              lines = layouter.fit([text], field['type'].in?(%w[date number]) ? width : area['w'] * width, height).lines

              box_height = lines.sum(&:height)
            end

            if box_height > (area['h'] * height) + 1
              text = HexaPDF::Layout::TextFragment.create(value,
                                                          font: pdf.fonts.add(FONT_NAME),
                                                          font_size: (font_size / 1.9).to_i)

              lines = layouter.fit([text], field['type'].in?(%w[date number]) ? width : area['w'] * width, height).lines

              box_height = lines.sum(&:height)
            end

            height_diff = [0, box_height - (area['h'] * height)].max

            right_align_x_adjustment =
              if field['type'].in?(%w[date number]) && text_align != :left
                (width - (area['w'] * width)) / (text_align == :center ? 2.0 : 1)
              else
                0
              end

            layouter.fit([text], field['type'].in?(%w[date number]) ? width : area['w'] * width,
                         height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, (area['x'] * width) - right_align_x_adjustment + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) + height_diff - TEXT_TOP_MARGIN)
          end
        end
      end

      pdfs_index
    end

    def build_pdf_attachment(pdf:, submitter:, pkcs:, tsa_url:, uuid:, name:)
      io = StringIO.new

      pdf.trailer.info[:Creator] = info_creator

      sign_reason = fetch_sign_reason(submitter)

      if sign_reason
        sign_params = {
          reason: sign_reason,
          **build_signing_params(pkcs, tsa_url)
        }

        begin
          pdf.sign(io, write_options: { validate: false }, **sign_params)
        rescue HexaPDF::MalformedPDFError => e
          Rollbar.error(e) if defined?(Rollbar)

          pdf.sign(io, write_options: { validate: false, incremental: false }, **sign_params)
        end
      else
        begin
          pdf.write(io, incremental: true, validate: false)
        rescue HexaPDF::MalformedPDFError => e
          Rollbar.error(e) if defined?(Rollbar)

          pdf.write(io, incremental: false, validate: false)
        end
      end
      # rubocop:enable Metrics

      ActiveStorage::Attachment.new(
        blob: ActiveStorage::Blob.create_and_upload!(io: StringIO.new(io.string), filename: "#{name}.pdf"),
        metadata: { original_uuid: uuid,
                    analyzed: true,
                    sha256: Base64.urlsafe_encode64(Digest::SHA256.digest(io.string)) },
        name: 'documents',
        record: submitter
      )
    end

    def build_signing_params(pkcs, tsa_url)
      params = {
        certificate: pkcs.certificate,
        key: pkcs.key,
        certificate_chain: pkcs.ca_certs || []
      }

      if tsa_url
        params[:timestamp_handler] = Submissions::TimestampHandler.new(tsa_url:)
        params[:signature_size] = 20_000
      end

      params
    end

    def images_pdf_uuid(attachments)
      Digest::UUID.uuid_v5(Digest::UUID::OID_NAMESPACE, attachments.map(&:uuid).sort.join(':'))
    end

    def build_pdfs_index(submitter, flatten: true)
      latest_submitter = find_last_submitter(submitter)

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

        pdf = maybe_rotate_pdf(pdf)

        if flatten
          begin
            pdf.acro_form.create_appearances(force: true) if pdf.acro_form && pdf.acro_form[:NeedAppearances]
            pdf.acro_form&.flatten
          rescue StandardError => e
            Rollbar.error(e) if defined?(Rollbar)
          end
        end

        pdf.config['font.on_missing_glyph'] = method(:on_missing_glyph).to_proc

        [attachment.metadata['original_uuid'] || attachment.uuid, pdf]
      end
    end

    def maybe_rotate_pdf(pdf)
      return pdf if pdf.pages.size > MAX_PAGE_ROTATE

      is_rotated = pdf.pages.filter_map do |page|
        page.rotate(0, flatten: true) if page[:Rotate] != 0
      end.present?

      return pdf unless is_rotated

      io = StringIO.new

      pdf.write(io, incremental: false, validate: false)

      HexaPDF::Document.new(io:)
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)

      pdf
    end

    def on_missing_glyph(character, font_wrapper)
      Rollbar.error("Missing glyph: #{character}") if character.present? && defined?(Rollbar)

      replace_with =
        if font_wrapper.font_type == :Type1
          MISSING_GLYPH_REPLACE_TYPE1[character] || :space
        else
          (MISSING_GLYPH_REPLACE[character] || ' ').bytes.first - 29
        end

      font_wrapper.custom_glyph(replace_with, character)
    end

    def find_last_submitter(submitter)
      submitter.submission.submitters
               .select(&:completed_at?)
               .select { |e| e.id != submitter.id && e.completed_at <= submitter.completed_at }
               .max_by(&:completed_at)
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

    def sign_reason(name)
      format(SIGN_REASON, name:)
    end

    def single_sign_reason(submitter)
      signers = submitter.submission.submitters.sort_by(&:completed_at).map { |s| s.email || s.name || s.phone }

      format(SIGN_REASON, name: signers.reverse.join(', '))
    end

    def fetch_sign_reason(submitter)
      reason_name = submitter.email || submitter.name || submitter.phone

      config =
        if Docuseal.multitenant?
          AccountConfig.where(account: submitter.account, key: AccountConfig::ESIGNING_PREFERENCE_KEY)
                       .first_or_initialize(value: 'single')
        else
          AccountConfig.where(key: AccountConfig::ESIGNING_PREFERENCE_KEY)
                       .first_or_initialize(value: 'single')
        end

      return sign_reason(reason_name) if config.value == 'multiple'

      if !submitter.submission.submitters.exists?(completed_at: nil) &&
         submitter.completed_at == submitter.submission.submitters.maximum(:completed_at)
        return single_sign_reason(submitter)
      end

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
