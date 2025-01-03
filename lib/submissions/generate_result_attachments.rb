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

    SIGN_REASON = 'Signed by %<name>s with DocuSeal.com'

    RTL_REGEXP = TextUtils::RTL_REGEXP

    TEXT_LEFT_MARGIN = 1
    TEXT_TOP_MARGIN = 1
    MAX_PAGE_ROTATE = 20

    A4_SIZE = [595, 842].freeze

    TESTING_FOOTER = 'Testing Document - NOT LEGALLY BINDING'

    MISSING_GLYPH_REPLACE = {
      '▪' => '-',
      '✔️' => 'V',
      '✔' => 'V',
      '✓' => 'V',
      '✅' => 'V'
    }.freeze

    MISSING_GLYPH_REPLACE_TYPE1 = {
      '▪' => :bullet,
      '✔️' => :V,
      '✔' => :V,
      '✓' => :V,
      '✅' => :V
    }.freeze

    module_function

    # rubocop:disable Metrics
    def call(submitter)
      return generate_detached_signature_attachments(submitter) if detached_signature?(submitter)

      pdfs_index = generate_pdfs(submitter)

      template = submitter.submission.template
      account = submitter.account

      pkcs = Accounts.load_signing_pkcs(account)
      tsa_url = Accounts.load_timeserver_url(account)

      image_pdfs = []
      original_documents = template.documents.preload(:blob)

      result_attachments =
        submitter.submission.template_schema.filter_map do |item|
          pdf = pdfs_index[item['attachment_uuid']]

          next if pdf.nil?

          if original_documents.find { |a| a.uuid == item['attachment_uuid'] }.image?
            pdf = normalize_image_pdf(pdf)

            image_pdfs << pdf
          end

          build_pdf_attachment(pdf:, submitter:, pkcs:, tsa_url:,
                               uuid: item['attachment_uuid'],
                               name: item['name'])
        end

      return ApplicationRecord.no_touching { result_attachments.map { |e| e.tap(&:save!) } } if image_pdfs.size < 2

      images_pdf =
        image_pdfs.each_with_object(HexaPDF::Document.new) do |pdf, doc|
          pdf.pages.each { |page| doc.pages << doc.import(page) }
        end

      images_pdf = normalize_image_pdf(images_pdf)

      images_pdf_attachment =
        build_pdf_attachment(
          pdf: images_pdf,
          submitter:,
          tsa_url:,
          pkcs:,
          uuid: images_pdf_uuid(original_documents.select(&:image?)),
          name: template.name
        )

      ApplicationRecord.no_touching do
        (result_attachments + [images_pdf_attachment]).map { |e| e.tap(&:save!) }
      end
    end

    def generate_pdfs(submitter)
      configs = submitter.account.account_configs.where(key: [AccountConfig::FLATTEN_RESULT_PDF_KEY,
                                                              AccountConfig::WITH_SIGNATURE_ID])

      with_signature_id = configs.find { |c| c.key == AccountConfig::WITH_SIGNATURE_ID }&.value == true
      is_flatten = configs.find { |c| c.key == AccountConfig::FLATTEN_RESULT_PDF_KEY }&.value != false

      pdfs_index = build_pdfs_index(submitter.submission, submitter:, flatten: is_flatten)

      if with_signature_id || submitter.account.testing?
        pdfs_index.each_value do |pdf|
          next if pdf.trailer.info[:DocumentID].present?

          font = pdf.fonts.add(FONT_NAME)

          document_id = Digest::MD5.hexdigest(submitter.submission.slug).upcase

          pdf.trailer.info[:DocumentID] = document_id
          pdf.pages.each do |page|
            font_size = (([page.box.width, page.box.height].min / A4_SIZE[0].to_f) * 9).to_i
            cnv = page.canvas(type: :overlay)

            text =
              if submitter.account.testing?
                if with_signature_id
                  "#{TESTING_FOOTER} | ID: #{document_id}"
                else
                  TESTING_FOOTER
                end
              else
                "#{I18n.t('document_id', locale: submitter.account.locale)}: #{document_id}"
              end

            text = HexaPDF::Layout::TextFragment.create(
              text, font:, font_size:, underlays: [
                lambda do |canv, box|
                  canv.fill_color('white').rectangle(-1, 0, box.width + 2, box.height).fill
                end
              ]
            )

            HexaPDF::Layout::TextLayouter.new(font:, font_size:)
                                         .fit([text], page.box.width, page.box.height)
                                         .draw(cnv, 1, font_size * 1.37)
          end
        end
      end

      fill_submitter_fields(submitter, submitter.account, pdfs_index, with_signature_id:, is_flatten:)
    end

    def fill_submitter_fields(submitter, account, pdfs_index, with_signature_id:, is_flatten:, with_headings: nil)
      cell_layouter = HexaPDF::Layout::TextLayouter.new(text_valign: :center, text_align: :center)

      attachments_data_cache = {}

      return pdfs_index if submitter.submission.template_fields.blank?

      with_headings = find_last_submitter(submitter.submission, submitter:).blank? if with_headings.nil?

      submitter.submission.template_fields.each do |field|
        next if field['type'] == 'heading' && !with_headings
        next if field['submitter_uuid'] != submitter.uuid && field['type'] != 'heading'

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

          preferences_font_size = field.dig('preferences', 'font_size').then { |num| num.present? ? num.to_i : nil }

          font_size   = preferences_font_size
          font_size ||= (([page.box.width, page.box.height].min / A4_SIZE[0].to_f) * FONT_SIZE).to_i

          fill_color = field.dig('preferences', 'color').presence

          font = pdf.fonts.add(field.dig('preferences', 'font').presence || FONT_NAME)

          value = submitter.values[field['uuid']]
          value = field['default_value'] if field['type'] == 'heading'

          text_align = field.dig('preferences', 'align').to_s.to_sym.presence ||
                       (value.to_s.match?(RTL_REGEXP) ? :right : :left)

          layouter = HexaPDF::Layout::TextLayouter.new(text_valign: :center, text_align:,
                                                       font:, font_size:)

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
          when ->(type) { type == 'signature' && (with_signature_id || field.dig('preferences', 'reason_field_uuid')) }
            attachment = submitter.attachments.find { |a| a.uuid == value }

            attachments_data_cache[attachment.uuid] ||= attachment.download

            image = Vips::Image.new_from_buffer(attachments_data_cache[attachment.uuid], '').autorot

            id_string = "ID: #{attachment.uuid}".upcase

            while true
              text = HexaPDF::Layout::TextFragment.create(id_string,
                                                          font:,
                                                          font_size: (font_size / 1.8).to_i)

              result = layouter.fit([text], area['w'] * width, (font_size / 1.8) / 0.65)

              break if result.status == :success

              id_string = "#{id_string.delete_suffix('...')[0..-2]}..."

              break if id_string.length < 8
            end

            reason_value = submitter.values[field.dig('preferences', 'reason_field_uuid')].presence

            reason_string =
              I18n.with_locale(submitter.account.locale) do
                "#{reason_value ? "#{I18n.t('reason')}: " : ''}#{reason_value || I18n.t('digitally_signed_by')} " \
                  "#{submitter.name}#{submitter.email.present? ? " <#{submitter.email}>" : ''}\n" \
                  "#{I18n.l(attachment.created_at.in_time_zone(submitter.account.timezone), format: :long)} " \
                  "#{TimeUtils.timezone_abbr(submitter.account.timezone, attachment.created_at)}"
              end

            reason_text = HexaPDF::Layout::TextFragment.create(reason_string,
                                                               font:,
                                                               font_size: (font_size / 1.8).to_i)

            reason_result = layouter.fit([reason_text], area['w'] * width, height)

            text_height = result.lines.sum(&:height) + reason_result.lines.sum(&:height)

            image_height = (area['h'] * height) - text_height
            image_height = (area['h'] * height) / 2 if image_height < (area['h'] * height) / 2

            scale = [(area['w'] * width) / image.width, image_height / image.height].min

            io = StringIO.new(image.resize([scale * 4, 1].select(&:positive?).min).write_to_buffer('.png'))

            layouter.fit([text], area['w'] * width, (font_size / 1.8) / 0.65)
                    .draw(canvas, (area['x'] * width) + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) - TEXT_TOP_MARGIN - image_height)

            layouter.fit([reason_text], area['w'] * width, reason_result.lines.sum(&:height))
                    .draw(canvas, (area['x'] * width) + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) - TEXT_TOP_MARGIN -
                          result.lines.sum(&:height) - image_height)

            canvas.image(
              io,
              at: [
                (area['x'] * width) + (area['w'] * width / 2) - ((image.width * scale) / 2),
                height - (area['y'] * height) - (image.height * scale / 2) - (image_height / 2)
              ],
              width: image.width * scale,
              height: image.height * scale
            )
          when 'image', 'signature', 'initials', 'stamp'
            attachment = submitter.attachments.find { |a| a.uuid == value }

            attachments_data_cache[attachment.uuid] ||= attachment.download

            image =
              begin
                Vips::Image.new_from_buffer(attachments_data_cache[attachment.uuid], '').autorot
              rescue Vips::Error
                next unless attachment.content_type.starts_with?('image/')
                next if attachment.byte_size.zero?

                raise
              end

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

              acc << HexaPDF::Layout::TextFragment.create("#{attachment.filename}\n", font:,
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

              option_name = option['value'].presence
              option_name ||= "#{I18n.t('option', locale: account.locale)} #{field['options'].index(option) + 1}"

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
          when ->(type) { type == 'cells' && !area['cell_w'].to_f.zero? }
            cell_width = area['cell_w'] * width

            chars = TextUtils.maybe_rtl_reverse(value).chars
            chars = chars.reverse if field.dig('preferences', 'align') == 'right'

            chars.each_with_index do |char, index|
              next if char.blank?

              text = HexaPDF::Layout::TextFragment.create(char, font:,
                                                                fill_color:,
                                                                font_size:)

              line_height = layouter.fit([text], cell_width, height).lines.first.height

              if preferences_font_size.blank? && line_height > (area['h'] * height)
                text = HexaPDF::Layout::TextFragment.create(char,
                                                            font:,
                                                            fill_color:,
                                                            font_size: (font_size / 1.4).to_i)

                line_height = layouter.fit([text], cell_width, height).lines.first.height
              end

              if preferences_font_size.blank? && line_height > (area['h'] * height)
                text = HexaPDF::Layout::TextFragment.create(char,
                                                            font:,
                                                            fill_color:,
                                                            font_size: (font_size / 1.9).to_i)

                line_height = layouter.fit([text], cell_width, height).lines.first.height
              end

              x =
                if field.dig('preferences', 'align') == 'right'
                  ((area['x'] + area['w']) * width) - (cell_width * (index + 1))
                else
                  (area['x'] * width) + (cell_width * index)
                end

              cell_layouter.fit([text], cell_width, [line_height, area['h'] * height].max)
                           .draw(canvas, x, height - (area['y'] * height))
            end
          else
            if field['type'] == 'date'
              value = TimeUtils.format_date_string(value, field.dig('preferences', 'format'), account.locale)
            end

            value = NumberUtils.format_number(value, field.dig('preferences', 'format')) if field['type'] == 'number'

            value = TextUtils.maybe_rtl_reverse(Array.wrap(value).join(', '))

            text = HexaPDF::Layout::TextFragment.create(value, font:,
                                                               fill_color:,
                                                               font_size:)

            lines = layouter.fit([text], area['w'] * width, height).lines
            box_height = lines.sum(&:height)

            if preferences_font_size.blank? && box_height > (area['h'] * height) + 1
              text = HexaPDF::Layout::TextFragment.create(value,
                                                          font:,
                                                          fill_color:,
                                                          font_size: (font_size / 1.4).to_i)

              lines = layouter.fit([text], field['type'].in?(%w[date number]) ? width : area['w'] * width, height).lines

              box_height = lines.sum(&:height)
            end

            if preferences_font_size.blank? && box_height > (area['h'] * height) + 1
              text = HexaPDF::Layout::TextFragment.create(value,
                                                          font:,
                                                          fill_color:,
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

      if sign_reason && pkcs
        sign_params = {
          reason: sign_reason,
          **build_signing_params(submitter, pkcs, tsa_url)
        }

        pdf.pages.first[:Annots] = [] unless pdf.pages.first[:Annots].respond_to?(:<<)

        begin
          pdf.sign(io, write_options: { validate: false }, **sign_params)
        rescue HexaPDF::MalformedPDFError => e
          Rollbar.error(e) if defined?(Rollbar)

          pdf.sign(io, write_options: { validate: false, incremental: false }, **sign_params)
        end

        maybe_enable_ltv(io, sign_params)
      else
        begin
          pdf.write(io, incremental: true, validate: false)
        rescue HexaPDF::MalformedPDFError => e
          Rollbar.error(e) if defined?(Rollbar)

          pdf.write(io, incremental: false, validate: false)
        end
      end

      ActiveStorage::Attachment.new(
        blob: ActiveStorage::Blob.create_and_upload!(io: io.tap(&:rewind), filename: "#{name}.pdf"),
        metadata: { original_uuid: uuid,
                    analyzed: true,
                    sha256: Base64.urlsafe_encode64(Digest::SHA256.digest(io.string)) },
        name: 'documents',
        record: submitter
      )
    end
    # rubocop:enable Metrics

    def maybe_enable_ltv(io, _sign_params)
      io
    end

    def build_signing_params(_submitter, pkcs, tsa_url)
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

    def build_pdfs_index(submission, submitter: nil, flatten: true)
      latest_submitter = find_last_submitter(submission, submitter:)

      Submissions::EnsureResultGenerated.call(latest_submitter) if latest_submitter

      documents   = latest_submitter&.documents&.preload(:blob).to_a.presence
      documents ||= submission.template_schema_documents.preload(:blob)

      attachment_uuids = Submissions.filtered_conditions_schema(submission).pluck('attachment_uuid')
      attachments_index = documents.index_by { |a| a.metadata['original_uuid'] || a.uuid }

      attachment_uuids.each_with_object({}) do |uuid, acc|
        attachment = attachments_index[uuid]
        attachment ||= submission.template_schema_documents.preload(:blob).find { |a| a.uuid == uuid }

        next unless attachment

        pdf =
          if attachment.image?
            build_pdf_from_image(attachment)
          else
            HexaPDF::Document.new(io: StringIO.new(attachment.download))
          end

        pdf = maybe_rotate_pdf(pdf)

        maybe_flatten_pdf(pdf) if flatten

        pdf.config['font.on_missing_glyph'] = method(:on_missing_glyph).to_proc

        acc[uuid] = pdf
      end
    end

    def maybe_flatten_pdf(pdf)
      pdf.acro_form.create_appearances(force: true) if pdf.acro_form && pdf.acro_form[:NeedAppearances]
      pdf.acro_form&.flatten
    rescue HexaPDF::MissingGlyphError
      nil
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
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
      Rails.logger.info("Missing glyph: #{character}") if character.present? && defined?(Rollbar)

      replace_with =
        if font_wrapper.font_type == :Type1
          MISSING_GLYPH_REPLACE_TYPE1[character] || :space
        else
          (MISSING_GLYPH_REPLACE[character] || ' ').bytes.first - 29
        end

      font_wrapper.custom_glyph(replace_with, character)
    end

    def find_last_submitter(submission, submitter: nil)
      submission.submitters
                .select(&:completed_at?)
                .select { |e| submitter.nil? ? true : e.id != submitter.id && e.completed_at <= submitter.completed_at }
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

    def normalize_image_pdf(pdf)
      io = StringIO.new
      pdf.write(io)
      io.rewind

      HexaPDF::Document.new(io:)
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

    def detached_signature?(_submitter)
      false
    end

    def generate_detached_signature_attachments(_submitter)
      []
    end

    def h
      Rails.application.routes.url_helpers
    end
  end
end
