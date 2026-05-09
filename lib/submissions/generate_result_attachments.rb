# frozen_string_literal: true

module Submissions
  module GenerateResultAttachments
    FONT_SIZE = 11
    FONT_PATH = '/fonts/GoNotoKurrent-Regular.ttf'
    FONT_BOLD_PATH = '/fonts/GoNotoKurrent-Bold.ttf'
    FONT_NAME = if File.exist?(FONT_PATH)
                  FONT_PATH
                else
                  'Helvetica'
                end

    ICO_REGEXP = %r{\Aimage/(?:x-icon|vnd\.microsoft\.icon)\z}
    BMP_REGEXP = %r{\Aimage/(?:bmp|x-bmp|x-ms-bmp)\z}

    FONT_BOLD_NAME = if File.exist?(FONT_BOLD_PATH)
                       FONT_BOLD_PATH
                     else
                       'Helvetica'
                     end

    FONT_ITALIC_NAME = 'Helvetica'
    FONT_BOLD_ITALIC_NAME = 'Helvetica'

    FONT_VARIANS = {
      none: FONT_NAME,
      bold: FONT_BOLD_NAME,
      italic: FONT_ITALIC_NAME,
      bold_italic: FONT_BOLD_ITALIC_NAME
    }.freeze

    PDFA_FONT_VARIANS = {
      none: FONT_NAME,
      bold: FONT_BOLD_NAME,
      italic: FONT_NAME,
      bold_italic: FONT_BOLD_NAME
    }.freeze

    SIGN_REASON = 'Signed with DocuSeal.com'

    RTL_REGEXP = TextUtils::RTL_REGEXP

    TEXT_LEFT_MARGIN = 1
    TEXT_TOP_MARGIN = 1
    MAX_PAGE_ROTATE = 50

    A4_SIZE = [595, 842].freeze

    TESTING_FOOTER = 'Testing Document - NOT LEGALLY BINDING'
    DEFAULT_FONTS = %w[Times Helvetica Courier].freeze
    FONTS_LINE_HEIGHT = {
      'Times' => 1.5,
      'Helvetica' => 1.5,
      'Courier' => 1.6
    }.freeze

    PDFA_FONT_MAP = {
      FONT_NAME => PDFA_FONT_VARIANS,
      'Helvetica' => PDFA_FONT_VARIANS,
      'Times' => PDFA_FONT_VARIANS,
      'Courier' => PDFA_FONT_VARIANS
    }.freeze

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

      account = submitter.account
      submission = submitter.submission

      pkcs = Accounts.load_signing_pkcs(account)
      tsa_url = Accounts.load_timeserver_url(account)

      image_pdfs = []
      original_documents = submission.schema_documents.preload(:blob)

      result_attachments =
        submission.template_schema.filter_map do |item|
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
          name: submission.name || submission.template.name
        )

      ApplicationRecord.no_touching do
        (result_attachments + [images_pdf_attachment]).map { |e| e.tap(&:save!) }
      end
    end

    def generate_pdfs(submitter)
      configs = submitter.account.account_configs.where(key: [AccountConfig::FLATTEN_RESULT_PDF_KEY,
                                                              AccountConfig::WITH_SIGNATURE_ID,
                                                              AccountConfig::WITH_FILE_LINKS_KEY,
                                                              AccountConfig::WITH_TIMESTAMP_SECONDS_KEY,
                                                              AccountConfig::ROTATE_INCREMENTAL_PDF_KEY,
                                                              AccountConfig::WITH_SUBMITTER_TIMEZONE_KEY,
                                                              AccountConfig::WITH_SIGNATURE_ID_REASON_KEY])

      with_signature_id = configs.find { |c| c.key == AccountConfig::WITH_SIGNATURE_ID }&.value != false
      is_flatten = configs.find { |c| c.key == AccountConfig::FLATTEN_RESULT_PDF_KEY }&.value != false
      is_rotate_incremental = configs.find { |c| c.key == AccountConfig::ROTATE_INCREMENTAL_PDF_KEY }&.value == true
      with_timestamp_seconds = configs.find { |c| c.key == AccountConfig::WITH_TIMESTAMP_SECONDS_KEY }&.value == true
      with_submitter_timezone = configs.find { |c| c.key == AccountConfig::WITH_SUBMITTER_TIMEZONE_KEY }&.value == true
      with_file_links = configs.find { |c| c.key == AccountConfig::WITH_FILE_LINKS_KEY }&.value == true
      with_signature_id_reason =
        configs.find { |c| c.key == AccountConfig::WITH_SIGNATURE_ID_REASON_KEY }&.value != false

      pdfs_index = build_pdfs_index(submitter.submission, submitter:, flatten: is_flatten,
                                                          incremental: is_rotate_incremental)

      if with_signature_id || submitter.account.testing?
        pdfs_index.each_value do |pdf|
          next if pdf.trailer.info[:DocumentID].present?

          font = pdf.fonts.add(FONT_NAME)

          document_id = Digest::MD5.hexdigest(submitter.submission.slug).upcase

          pdf.trailer.info[:DocumentID] = document_id
          pdf.pages.each do |page|
            font_size = [(([page.box.width, page.box.height].min / A4_SIZE[0].to_f) * 9).to_i, 4].max
            cnv = page.canvas(type: :overlay)

            text =
              if submitter.account.testing?
                if with_signature_id
                  "#{TESTING_FOOTER} | ID: #{document_id}"
                else
                  TESTING_FOOTER
                end
              else
                "#{I18n.t('document_id',
                          locale: submitter.metadata.fetch('lang', submitter.account.locale))}: #{document_id}"
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

      fill_submitter_fields(submitter, submitter.account, pdfs_index, with_signature_id:, is_flatten:,
                                                                      with_submitter_timezone:,
                                                                      with_file_links:,
                                                                      with_timestamp_seconds:,
                                                                      with_signature_id_reason:)
    end

    def fill_submitter_fields(submitter, account, pdfs_index, with_signature_id:, is_flatten:, with_headings: nil,
                              with_submitter_timezone: false, with_signature_id_reason: true,
                              with_timestamp_seconds: false, with_file_links: nil)
      cell_layouters = Hash.new do |hash, valign|
        hash[valign] = HexaPDF::Layout::TextLayouter.new(text_valign: valign.to_sym, text_align: :center)
      end

      attachments_data_cache = {}

      submission = submitter.submission

      with_headings = find_last_submitter(submission, submitter:).blank? if with_headings.nil?

      locale = submitter.metadata.fetch('lang', account.locale)

      (submission.template_fields || submission.template.fields).each do |field|
        next if !with_headings &&
                (field['type'] == 'heading' || (field['type'] == 'strikethrough' && field['conditions'].blank?))

        next if field['submitter_uuid'] != submitter.uuid && field['type'] != 'heading' &&
                (field['type'] != 'strikethrough' || field['conditions'].present?)

        field.fetch('areas', []).each do |area|
          pdf = pdfs_index[area['attachment_uuid']]

          next if pdf.nil?

          page = pdf.pages[area['page']]

          next if page.nil?

          page.rotate(0, flatten: true) if page[:Rotate] != 0

          page[:Annots] ||= []
          page[:Annots] = page[:Annots].try(:reject) do |e|
            next if e.is_a?(Integer) || e.is_a?(Symbol) || e.is_a?(HexaPDF::PDFArray)

            e.present? && e[:A] && !e[:A].is_a?(HexaPDF::PDFArray) &&
              e[:A][:URI].to_s.starts_with?('file:///docuseal_field')
          end || page[:Annots]

          width = page.box.width
          height = page.box.height

          preferences_font_size = field.dig('preferences', 'font_size').then { |num| num.presence&.to_i }

          font_size   = preferences_font_size
          font_size ||= (([page.box.width, page.box.height].min / A4_SIZE[0].to_f) * FONT_SIZE).to_i

          fill_color = field.dig('preferences', 'color').to_s.delete_prefix('#').presence
          bg_color = field.dig('preferences', 'background').to_s.delete_prefix('#').presence

          font_name = field.dig('preferences', 'font')
          font_variant = (field.dig('preferences', 'font_type').presence || 'none').to_sym

          font_name = FONT_NAME unless font_name.in?(DEFAULT_FONTS)

          if font_variant != :none && font_name == FONT_NAME
            font_name = FONT_VARIANS[font_variant] if FONT_VARIANS[font_variant]
            font_variant = nil unless font_name.in?(DEFAULT_FONTS)
          end

          font = pdf.fonts.add(font_name, variant: font_variant, custom_encoding: font_name.in?(DEFAULT_FONTS))

          value = submitter.values[field['uuid']]
          value = field['default_value'] if field['type'] == 'heading'
          value = field['default_value'] if field['type'] == 'strikethrough' && value.nil? && field['conditions'].blank?

          text_align = field.dig('preferences', 'align').to_s.to_sym.presence ||
                       (value.to_s.match?(RTL_REGEXP) ? :right : :left)

          text_valign = (field.dig('preferences', 'valign').to_s.presence || 'center').to_sym

          layouter = HexaPDF::Layout::TextLayouter.new(text_valign:, text_align:, font:, font_size:)

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

          field_type = field['type']
          field_type = 'file' if field_type == 'image' &&
                                 !submitter.attachments.find { |a| a.uuid == value }.image?

          if field_type == 'signature' && field.dig('preferences', 'with_signature_id').in?([true, false])
            with_signature_id = field['preferences']['with_signature_id']
          end

          if bg_color.present?
            canvas.fill_color(bg_color)
                  .rectangle(area['x'] * width, height - (area['y'] * height) - (area['h'] * height),
                             area['w'] * width, area['h'] * height)
                  .fill
          end

          case field_type
          when ->(type) { (type == 'signature' || type == 'initials') && with_signature_id }
            attachment = submitter.attachments.find { |a| a.uuid == value }

            image =
              begin
                load_vips_image(attachment, attachments_data_cache).autorot
              rescue Vips::Error
                next unless attachment.content_type.starts_with?('image/')
                next if attachment.byte_size.zero?

                raise
              end

            page_base_size = (([width, height].min / A4_SIZE[0].to_f) * FONT_SIZE).to_i
            base_font_size = (page_base_size / 1.8).to_i
            base_font_size = 4 if base_font_size < 4

            area_x = area['x'] * width
            area_y = area['y'] * height
            area_w = area['w'] * width
            area_h = area['h'] * height

            timezone = with_submitter_timezone ? (submitter.timezone || submitter.account.timezone) : submitter.account.timezone
            time_format = with_timestamp_seconds ? :detailed : :long
            caption_string =
              I18n.with_locale(locale) do
                if field_type == 'initials'
                  date_str = I18n.l(attachment.created_at.in_time_zone(timezone).to_date, format: :long)
                  with_signature_id_reason ? "#{submitter.name} · #{date_str}" : date_str
                else
                  timestamp_str = "#{I18n.l(attachment.created_at.in_time_zone(timezone), format: time_format)} " \
                                  "#{TimeUtils.timezone_abbr(timezone, attachment.created_at)}"
                  with_signature_id_reason ? "#{submitter.name} · #{timestamp_str}" : timestamp_str
                end
              end
            doc_id_full = Digest::MD5.hexdigest(submitter.submission.slug).upcase
            header_string =
              if field_type == 'signature'
                "#{I18n.with_locale(locale) { I18n.t('digitally_signed_by') }}:"
              else
                "#{I18n.with_locale(locale) { I18n.t('initials') }}:"
              end
            id_string = "#{doc_id_full[0, 16]}..."

            amber_border = HexaPDF::Content::ColorSpace::DeviceRGB.new.color(0.71, 0.45, 0.05)
            slate_text = HexaPDF::Content::ColorSpace::DeviceRGB.new.color(0.16, 0.16, 0.20)
            muted_text = HexaPDF::Content::ColorSpace::DeviceRGB.new.color(0.42, 0.45, 0.50)

            bracket_r = [area_h * 0.18, base_font_size * 1.2, 7].max
            inner_left = area_x + bracket_r + 4
            inner_right = area_x + area_w - 1
            content_w = inner_right - inner_left

            header_h = base_font_size * 1.4
            header_gap = base_font_size * 0.2
            line_h = base_font_size * 1.25
            min_image_h = base_font_size * 2.5

            # Signature: header + image + caption (name · timestamp) + ID. Initials: header + image only.
            footer_lines = field_type == 'signature' ? 2 : 0
            while footer_lines > 0 && (area_h - header_h - header_gap - (line_h * footer_lines)) < min_image_h
              footer_lines -= 1
            end
            footer_h = line_h * footer_lines

            available_image_h = area_h - header_h - header_gap - footer_h
            available_image_h = min_image_h if available_image_h < min_image_h

            box_y_top = height - area_y
            box_y_bottom = (height - area_y) - area_h

            size_factor = field_type == 'initials' ? 0.55 : 0.85
            inner_image_w = (content_w - 2) * size_factor
            inner_image_h = available_image_h * size_factor
            scale = [[inner_image_w / image.width, inner_image_h / image.height].min, 0.0001].max
            image_w_drawn = image.width * scale
            image_h_drawn = image.height * scale

            tail_h = field_type == 'initials' ? base_font_size * 0.6 : 0
            content_h = header_h + header_gap + image_h_drawn + footer_h + tail_h
            content_h = [content_h, area_h].min
            bracket_y_top = box_y_top
            bracket_y_bottom = box_y_top - content_h

            image_y_top = box_y_top - header_h - header_gap
            image_y_bottom = image_y_top - image_h_drawn
            image_x_left = inner_left + ((content_w - image_w_drawn) / 2.0)

            canvas.save_graphics_state do
              canvas.fill_color(255, 255, 255)
                    .rectangle(area_x, box_y_bottom, area_w, area_h)
                    .fill
            end

            header_font = pdf.fonts.add('Helvetica', variant: :bold)
            label_font = pdf.fonts.add('Helvetica')
            header_text = HexaPDF::Layout::TextFragment.create(header_string, font: header_font,
                                                                              font_size: base_font_size,
                                                                              fill_color: slate_text)
            HexaPDF::Layout::TextLayouter.new(font: header_font, font_size: base_font_size, text_align: :left)
                                         .fit([header_text], content_w, header_h)
                                         .draw(canvas, inner_left, box_y_top - 1)

            io = StringIO.new(image.resize([scale * 4, 1].select(&:positive?).min).write_to_buffer('.png'))
            image_x_left_aligned = inner_left
            canvas.image(io,
                         at: [image_x_left_aligned, image_y_bottom],
                         width: image_w_drawn,
                         height: image_h_drawn)

            canvas.save_graphics_state do
              canvas.stroke_color(amber_border).line_width(0.9).line_cap_style(:round).line_join_style(:round)
              k = bracket_r * 0.5523
              top_stub_end_x = inner_left - 1
              top_stub_len = top_stub_end_x - (area_x + bracket_r)
              bottom_stub_end_x = (area_x + bracket_r) + (top_stub_len * 1.12)
              canvas.move_to(top_stub_end_x, bracket_y_top)
                    .line_to(area_x + bracket_r, bracket_y_top)
                    .curve_to(area_x, bracket_y_top - bracket_r,
                              p1: [area_x + bracket_r - k, bracket_y_top],
                              p2: [area_x, bracket_y_top - bracket_r + k])
                    .line_to(area_x, bracket_y_bottom + bracket_r)
                    .curve_to(area_x + bracket_r, bracket_y_bottom,
                              p1: [area_x, bracket_y_bottom + bracket_r - k],
                              p2: [area_x + bracket_r - k, bracket_y_bottom])
                    .line_to(bottom_stub_end_x, bracket_y_bottom)
                    .stroke
            end

            if footer_lines >= 1
              caption_text = HexaPDF::Layout::TextFragment.create(caption_string, font: label_font,
                                                                                  font_size: base_font_size,
                                                                                  fill_color: slate_text)
              HexaPDF::Layout::TextLayouter.new(font: label_font, font_size: base_font_size, text_align: :left)
                                           .fit([caption_text], content_w, line_h)
                                           .draw(canvas, inner_left, image_y_bottom)
            end

            if footer_lines >= 2
              id_font_size = [base_font_size * 0.85, 4].max
              id_text = HexaPDF::Layout::TextFragment.create(id_string, font: label_font, font_size: id_font_size,
                                                                        fill_color: muted_text)
              HexaPDF::Layout::TextLayouter.new(font: label_font, font_size: id_font_size, text_align: :left)
                                           .fit([id_text], content_w, line_h)
                                           .draw(canvas, inner_left, image_y_bottom - line_h)
            end
          when 'image', 'signature', 'initials', 'stamp', 'kba'
            attachment = submitter.attachments.find { |a| a.uuid == value }

            image =
              begin
                load_vips_image(attachment, attachments_data_cache).autorot
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

              acc << HexaPDF::Layout::TextFragment.create("#{attachment.filename}\n", font:, font_size:)
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

              url =
                if with_file_links
                  ActiveStorage::Blob.proxy_url(attachment.blob)
                else
                  r.submissions_preview_url(submission.slug, **Docuseal.default_url_options)
                end

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
                  A: { Type: :Action, S: :URI, URI: url }
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

              value =
                if option
                  option_name = option['value'].presence
                  option_name ||= "#{I18n.t('option', locale: locale)} #{field['options'].index(option) + 1}"

                  Array.wrap(value).include?(option_name)
                else
                  Rollbar.error("Invalid option: #{field['uuid']}") if defined?(Rollbar)

                  false
                end
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
            cell_valign = field.dig('preferences', 'valign').to_s.presence || 'center'
            cell_layouter = cell_layouters[cell_valign]

            if (mask = field.dig('preferences', 'mask').presence)
              value = TextUtils.mask_value(value, mask)
            end

            chars = TextUtils.maybe_rtl_reverse(value).chars
            chars = chars.reverse if field.dig('preferences', 'align') == 'right'

            chars.each_with_index do |char, index|
              next if char.blank?

              text = HexaPDF::Layout::TextFragment.create(char, font:,
                                                                fill_color:,
                                                                font_size:)

              line = layouter.fit([text], width, height).lines.first

              line_height = line.height

              cell_width = [line.width, cell_width].max

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
          when 'strikethrough'
            scale = 1000.0 / width

            line_width = 6.0 / scale
            area_height = area['h'] * height

            if area_height * scale < 40.0
              canvas.tap do |c|
                c.stroke_color(field.dig('preferences', 'color').presence || 'red')
                c.line_width(line_width)
                c.line(width * area['x'],
                       height - (height * area['y']) - (area_height / 2),
                       (width * area['x']) + (width * area['w']),
                       height - (height * area['y']) - (area_height / 2))
                c.stroke
              end
            else
              canvas.tap do |c|
                c.stroke_color(field.dig('preferences', 'color').presence || 'red')
                c.line_width(line_width)
                c.line((width * area['x']) + (line_width / 2),
                       height - (height * area['y']) - (line_width / 2),
                       (width * area['x']) + (width * area['w']) - (line_width / 2),
                       height - (height * area['y']) - area_height + (line_width / 2))
                c.stroke
              end

              canvas.tap do |c|
                c.stroke_color(field.dig('preferences', 'color').presence || 'red')
                c.line_width(line_width)
                c.line((width * area['x']) + (line_width / 2),
                       height - (height * area['y']) - area_height + (line_width / 2),
                       (width * area['x']) + (width * area['w']) - (line_width / 2),
                       height - (height * area['y']) - (line_width / 2))
                c.stroke
              end
            end
          else
            if field['type'] == 'date'
              timezone = submitter.account.timezone
              timezone = submitter.timezone || submitter.account.timezone if with_submitter_timezone

              value = TimeUtils.format_date_string(value, field.dig('preferences', 'format'), locale, timezone:)
            end

            value = NumberUtils.format_number(value, field.dig('preferences', 'format')) if field['type'] == 'number'

            value = TextUtils.maybe_rtl_reverse(Array.wrap(value).join(', '))

            if (mask = field.dig('preferences', 'mask').presence)
              value = TextUtils.mask_value(value, mask)
            end

            text_params = { font:, fill_color:, font_size: }
            text_params[:line_height] = text_params[:font_size] * (FONTS_LINE_HEIGHT[font_name] || 1)

            text = HexaPDF::Layout::TextFragment.create(value.tr("\u00A0", ' '), **text_params)

            lines = layouter.fit([text], area['w'] * width, height).lines
            box_height = lines.sum(&:height)

            if preferences_font_size.blank? && box_height > (area['h'] * height) + 1
              text_params[:font_size] = (font_size / 1.4).to_i
              text_params[:line_height] = text_params[:font_size] * (FONTS_LINE_HEIGHT[font_name] || 1)

              text = HexaPDF::Layout::TextFragment.create(value, **text_params)

              lines = layouter.fit([text], field['type'].in?(%w[date number]) ? width : area['w'] * width, height).lines

              box_height = lines.sum(&:height)
            end

            if preferences_font_size.blank? && box_height > (area['h'] * height) + 1
              text_params[:font_size] = (font_size / 1.9).to_i
              text_params[:line_height] = text_params[:font_size] * (FONTS_LINE_HEIGHT[font_name] || 1)

              text = HexaPDF::Layout::TextFragment.create(value, **text_params)

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

            align_y_diff =
              if text_valign == :top
                0
              elsif text_valign == :bottom
                height_diff + TEXT_TOP_MARGIN
              else
                height_diff / 2
              end

            layouter.fit([text], field['type'].in?(%w[date number]) ? width : area['w'] * width,
                         height_diff.positive? ? box_height : area['h'] * height)
                    .draw(canvas, (area['x'] * width) - right_align_x_adjustment + TEXT_LEFT_MARGIN,
                          height - (area['y'] * height) + align_y_diff - TEXT_TOP_MARGIN)
          end
        end
      end

      pdfs_index
    end

    def build_pdf_attachment(pdf:, submitter:, pkcs:, tsa_url:, uuid:, name:)
      io = StringIO.new

      pdf.trailer.info[:Creator] = info_creator

      if Docuseal.pdf_format == 'pdf/a-3b'
        pdf.task(:pdfa, level: '3b')
        pdf.config['font.map'] = PDFA_FONT_MAP
      end

      sign_reason = fetch_sign_reason(submitter)

      if sign_reason && pkcs
        sign_params = {
          reason: sign_reason,
          **build_signing_params(submitter, pkcs, tsa_url)
        }

        pdf.pages.first[:Annots] = [] unless pdf.pages.first[:Annots].respond_to?(:<<)

        begin
          pdf.sign(io, write_options: { validate: false }, **sign_params)
        rescue HexaPDF::Error, NoMethodError => e
          Rollbar.error(e) if defined?(Rollbar)

          begin
            pdf.sign(io, write_options: { validate: false, incremental: false }, **sign_params)
          rescue HexaPDF::Error
            pdf.validate(auto_correct: true)
            pdf.sign(io, write_options: { validate: false, incremental: false }, **sign_params)
          end
        end

        maybe_enable_ltv(io, sign_params)
      else
        begin
          pdf.write(io, incremental: true, validate: false)
        rescue HexaPDF::Error, NoMethodError => e
          Rollbar.error(e) if defined?(Rollbar)

          begin
            pdf.write(io, incremental: false, validate: false)
          rescue HexaPDF::Error
            pdf.validate(auto_correct: true)
            pdf.write(io, incremental: false, validate: false)
          end
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

    def build_pdfs_index(submission, submitter: nil, flatten: true, incremental: false)
      latest_submitter = find_last_submitter(submission, submitter:)

      documents   = Submissions::EnsureResultGenerated.call(latest_submitter) if latest_submitter
      documents ||= submission.schema_documents

      ActiveRecord::Associations::Preloader.new(records: documents, associations: [:blob]).call

      attachment_uuids = Submissions.filtered_conditions_schema(submission).pluck('attachment_uuid')
      attachments_index = documents.index_by { |a| a.metadata['original_uuid'] || a.uuid }

      attachment_uuids.each_with_object({}) do |uuid, acc|
        attachment = attachments_index[uuid]
        attachment ||= submission.schema_documents.preload(:blob).find { |a| a.uuid == uuid }

        next unless attachment

        pdf =
          if attachment.image?
            build_pdf_from_image(attachment)
          else
            HexaPDF::Document.new(io: StringIO.new(attachment.download))
          end

        pdf = maybe_rotate_pdf(pdf, incremental:)

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

    def maybe_rotate_pdf(pdf, incremental: false)
      return pdf if pdf.pages.size > MAX_PAGE_ROTATE

      is_pages_rotated = pdf.pages.root[:Rotate].present? && pdf.pages.root[:Rotate] != 0

      pdf.pages.root[:Rotate] = 0 if is_pages_rotated

      is_rotated = pdf.pages.filter_map do |page|
        page.rotate(0, flatten: true) if page[:Rotate] != 0
      end.present?

      return pdf if !is_rotated && !is_pages_rotated

      io = StringIO.new

      pdf.write(io, incremental:, validate: false)

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
                .select { |e| submitter.nil? || (e.id != submitter.id && e.completed_at <= submitter.completed_at) }
                .max_by(&:completed_at)
    end

    def build_pdf_from_image(attachment)
      pdf = HexaPDF::Document.new

      page = pdf.pages.add

      image = attachment.preview_images.first

      scale = [A4_SIZE.first / image.metadata['width'].to_f,
               A4_SIZE.last / image.metadata['height'].to_f].min

      page.box.width = image.metadata['width'] * scale
      page.box.height = image.metadata['height'] * scale

      page.canvas.image(
        StringIO.new(image.download),
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

    def load_vips_image(attachment, cache = {})
      cache[attachment.uuid] ||= attachment.download

      data = cache[attachment.uuid]

      if ICO_REGEXP.match?(attachment.content_type)
        LoadIco.call(data)
      elsif BMP_REGEXP.match?(attachment.content_type)
        LoadBmp.call(data)
      else
        Vips::Image.new_from_buffer(data, '')
      end
    end

    def r
      Rails.application.routes.url_helpers
    end
  end
end
