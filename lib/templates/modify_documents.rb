# frozen_string_literal: true

module Templates
  module ModifyDocuments
    InvalidLayout = Class.new(StandardError)

    A4_SIZE = [595, 842].freeze
    LETTER_SIZE = [612, 792].freeze
    PAGE_SIZE_TOLERANCE = 6
    SCAN_WHITE_THRESHOLD = 220
    SCAN_WHITE_FRACTION = 0.6
    ANNOTATIONS_SIZE_LIMIT = 6.megabytes
    ROTATIONS = [0, 90, 180, 270].freeze
    RECT_KEYS = %w[x y w h].freeze

    module_function

    def call(template, documents_layout)
      layout_attachment_uuids =
        documents_layout.flat_map { |e| [e['attachment_uuid'], e['pages'].to_a.pluck('attachment_uuid')] }.flatten.uniq

      attachments_index =
        template.documents_attachments.preload(:blob).where(uuid: layout_attachment_uuids).index_by(&:uuid)

      validate_layout!(template, documents_layout, attachments_index)

      mapping = {}

      new_schema = build_new_schema(template, documents_layout, attachments_index, mapping)

      template.schema.each_with_index do |item, index|
        new_schema.insert([index, new_schema.size].min, item) if item['dynamic']
      end

      removed_field_uuids = remap_fields(template, mapping)

      template.schema = new_schema

      remove_conditions(template.fields, removed_field_uuids)
      remove_conditions(template.schema, removed_field_uuids)

      template.save!

      template
    end

    def build_new_schema(template, documents_layout, attachments_index, mapping)
      sources = {}

      Pdfium.with_instance do
        documents_layout.filter_map do |entry|
          schema_item =
            template.schema.find { |item| item['attachment_uuid'] == entry['attachment_uuid'] } ||
            { 'attachment_uuid' => entry['attachment_uuid'],
              'name' => attachments_index[entry['attachment_uuid']].filename.base }

          next if entry['pages'].blank?

          if unchanged_entry?(entry, attachments_index)
            entry['pages'].each_with_index do |ref, index|
              add_page_mapping(mapping, ref, [ref['attachment_uuid'], index])
            end

            schema_item
          else
            document = if standalone_image_entry?(entry, attachments_index)
                         build_image_document(template, entry, attachments_index)
                       else
                         build_document(template, schema_item, entry['pages'], attachments_index, sources)
                       end

            entry['pages'].each_with_index do |ref, index|
              add_page_mapping(mapping, ref, [document.uuid, index, ref['rotate'].to_i % 360])
            end

            schema_item.except('google_drive_file_id').merge('attachment_uuid' => document.uuid)
          end
        end
      ensure
        sources.each_value(&:close)
      end
    end

    def add_page_mapping(mapping, ref, target)
      mapping[[ref['attachment_uuid'], ref['page']]] = target

      replaced = ref['replaced_page']

      mapping[[replaced['attachment_uuid'], replaced['page']]] = target if replaced
    end

    def validate_layout!(template, documents_layout, attachments_index)
      raise InvalidLayout if documents_layout.blank?
      raise InvalidLayout if documents_layout.all? { |entry| entry['pages'].blank? }

      dynamic_uuids = template.schema.select { |item| item['dynamic'] }.pluck('attachment_uuid')
      non_dynamic_uuids = template.schema.pluck('attachment_uuid') - dynamic_uuids
      layout_uuids = documents_layout.pluck('attachment_uuid')

      raise InvalidLayout if layout_uuids.uniq.size != layout_uuids.size
      raise InvalidLayout if (non_dynamic_uuids - layout_uuids).any?
      raise InvalidLayout if layout_uuids.intersect?(dynamic_uuids)
      raise InvalidLayout if layout_uuids.any? { |uuid| attachments_index[uuid].nil? }

      refs = documents_layout.flat_map { |entry| entry['pages'].to_a }

      refs.each { |ref| validate_ref!(ref, attachments_index) }

      ref_keys = refs.map { |ref| [ref['attachment_uuid'], ref['page']] }

      raise InvalidLayout if ref_keys.uniq.size != ref_keys.size
    end

    def validate_ref!(ref, attachments_index)
      attachment = attachments_index[ref['attachment_uuid']]

      raise InvalidLayout if attachment.nil?

      raise InvalidLayout unless ref['page'].is_a?(Integer) &&
                                 ref['page'] >= 0 && ref['page'] < page_count(attachment)
      raise InvalidLayout unless ref['rotate'].nil? || ROTATIONS.include?(ref['rotate'])

      validate_redact!(ref['redact'])
    end

    def validate_redact!(redact)
      return if redact.nil?

      raise InvalidLayout unless redact.is_a?(Array)

      redact.each do |rect|
        valid = RECT_KEYS.all? { |key| rect[key].is_a?(Numeric) && rect[key].to_f.between?(-1, 2) }

        raise InvalidLayout unless valid
      end
    end

    def page_count(attachment)
      if attachment.content_type == Templates::ProcessDocument::PDF_CONTENT_TYPE
        attachment.metadata.dig('pdf', 'number_of_pages').to_i
      else
        1
      end
    end

    def page_objects(attachment, page_number)
      Pdfium::Document.open_bytes(attachment.download) do |doc|
        page = doc.get_page(page_number)

        page.flatten
        page.unwrap_form_objects
        page.rotate

        text_nodes = page.text_nodes.map do |node|
          { 'text' => node.content, 'x' => node.x, 'y' => node.y, 'w' => node.w, 'h' => node.h }
        end

        image_nodes = page.image_nodes.map do |node|
          { 'x' => node.x, 'y' => node.y, 'w' => node.w, 'h' => node.h }
        end

        { 'text_nodes' => text_nodes, 'image_nodes' => image_nodes }
      end
    end

    def unchanged_entry?(entry, attachments_index)
      uuid = entry['attachment_uuid']

      entry['pages'].size == page_count(attachments_index[uuid]) &&
        entry['pages'].each_with_index.all? do |ref, index|
          ref['attachment_uuid'] == uuid && ref['page'] == index && ref['rotate'].to_i.zero? && ref['redact'].blank?
        end
    end

    def build_document(template, schema_item, page_refs, attachments_index, sources)
      with_images = page_refs.any? { |ref| attachments_index[ref['attachment_uuid']].image? }

      pdf_size = entry_pdf_page_size(page_refs, attachments_index, sources) if with_images
      default_size = default_page_size(template.account) if with_images

      io =
        Pdfium::Document.create do |dest|
          insert_index = 0

          build_page_runs(page_refs, attachments_index).each do |uuid, pages_range, length, image_ops|
            redact, rotate = image_ops

            attachment = attachments_index[uuid]
            key = attachment.image? ? [uuid, image_ops, pdf_size, default_size] : [uuid, image_ops]

            source = sources[key] ||= open_or_build_pdf(attachment, redact:, rotate:, pdf_size:, default_size:)

            dest.import_pages(source, pages: pages_range, index: insert_index)

            insert_index += length
          end

          apply_pdf_page_ops(dest, page_refs, attachments_index)

          dest.save(StringIO.new)
        end

      save_document(template, attachments_index[schema_item['attachment_uuid']], io.string)
    end

    def apply_pdf_page_ops(dest, page_refs, attachments_index)
      page_refs.each_with_index do |ref, index|
        next if attachments_index[ref['attachment_uuid']].image?

        rotate = ref['rotate'].to_i % 360
        redact = ref['redact'].to_a

        next if rotate.zero? && redact.blank?

        page = dest.get_page(index)

        page.redact(redact) { |bitmap, pixel_rects| encode_redacted_image_jpeg(bitmap, pixel_rects) } if redact.present?

        next if rotate.zero?

        page.rotation = (page.rotation + (rotate / 90)) % 4

        page.rotate
      end
    end

    def build_page_runs(page_refs, attachments_index)
      runs = []

      page_refs.each do |ref|
        image_ops =
          if attachments_index[ref['attachment_uuid']].image?
            [ref['redact'].presence, ref['rotate'].to_i % 360].presence
          end

        if runs.last && runs.last[0] == ref['attachment_uuid'] && runs.last[2] == image_ops
          runs.last[1] << ref['page']
        else
          runs << [ref['attachment_uuid'], [ref['page']], image_ops]
        end
      end

      runs.map do |uuid, pages, image_ops|
        [uuid, pages.map { |page| page + 1 }.join(','), pages.size, image_ops]
      end
    end

    def standalone_image_entry?(entry, attachments_index)
      entry['pages'].size == 1 && attachments_index[entry['pages'].first['attachment_uuid']].image?
    end

    def build_image_document(template, entry, attachments_index)
      ref = entry['pages'].first
      attachment = attachments_index[ref['attachment_uuid']]

      return attachment if ref['redact'].blank? && (ref['rotate'].to_i % 360).zero?

      image = ImageUtils.load_vips(attachment.download, content_type: attachment.content_type, autorot: true)
      image = draw_image_redaction(image, ref['redact']) if ref['redact'].present?
      image = rotate_vips_image(image, ref['rotate'].to_i % 360)

      extension, format_args =
        if attachment.content_type == 'image/jpeg'
          ['.jpg', { Q: 90 }]
        else
          ['.png', {}]
        end

      data = image.write_to_buffer(extension, **format_args)

      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(data),
        filename: attachment.filename.to_s,
        metadata: { identified: true, analyzed: true },
        content_type: attachment.content_type
      )

      document = template.documents.create!(blob:)

      Templates::ProcessDocument.call(document, data)
    end

    def rotate_vips_image(image, rotate)
      case rotate
      when 90 then image.rot90
      when 180 then image.rot180
      when 270 then image.rot270
      else image
      end
    end

    def encode_redacted_image_jpeg(bitmap, pixel_rects)
      image = Vips::Image.new_from_memory_copy(bitmap[:data], bitmap[:width], bitmap[:height], bitmap[:bands], :uchar)

      image =
        case bitmap[:format]
        when :bgr, :bgrx then image[2].bandjoin([image[1], image[0]])
        when :bgra then image[2].bandjoin([image[1], image[0], image[3]]).flatten(background: 255)
        else image
        end

      pixel_rects.each do |left, top, rect_width, rect_height, color|
        image = image.draw_rect(redaction_ink(image.bands, color), left, top, rect_width, rect_height, fill: true)
      end

      image.write_to_buffer('.jpg', Q: 50, strip: true)
    end

    def draw_image_redaction(image, rects)
      rects.each do |rect|
        ink = redaction_ink(image.bands, rect['color'])

        left = (rect['x'].to_f * image.width).floor.clamp(0, image.width - 1)
        top = (rect['y'].to_f * image.height).floor.clamp(0, image.height - 1)
        rect_width = (rect['w'].to_f * image.width).ceil.clamp(1, image.width - left)
        rect_height = (rect['h'].to_f * image.height).ceil.clamp(1, image.height - top)

        image = image.draw_rect(ink, left, top, rect_width, rect_height, fill: true)
      end

      image
    end

    def redaction_ink(bands, color)
      value = color == 'white' ? 255.0 : 0.0

      Array.new(bands) { |band| band == 3 ? 255.0 : value }
    end

    def open_or_build_pdf(attachment, redact: nil, rotate: nil, pdf_size: nil, default_size: nil)
      data =
        if attachment.image?
          build_pdf_data_from_image(attachment, pdf_size, default_size, redact:, rotate:)
        else
          attachment.download
        end

      Pdfium::Document.open_bytes(data)
    end

    def entry_pdf_page_size(page_refs, attachments_index, sources)
      pdf_ref = page_refs.rfind { |ref| !attachments_index[ref['attachment_uuid']].image? }

      return if pdf_ref.nil?

      uuid = pdf_ref['attachment_uuid']
      source = sources[[uuid, nil]] ||= open_or_build_pdf(attachments_index[uuid])
      page = source.get_page(pdf_ref['page'])

      width = page.width
      height = page.height

      width, height = height, width unless (pdf_ref['rotate'].to_i % 180).zero?

      size = standard_page_size(width, height)

      return if size.nil?

      width > height ? size.reverse : size
    end

    def standard_page_size(width, height)
      [LETTER_SIZE, A4_SIZE].find do |size|
        [size, size.reverse].any? do |(base_width, base_height)|
          (width - base_width).abs <= PAGE_SIZE_TOLERANCE && (height - base_height).abs <= PAGE_SIZE_TOLERANCE
        end
      end
    end

    def default_page_size(account)
      abbr = TimeUtils.timezone_abbr(account.timezone, Time.current.beginning_of_year)

      abbr.in?(TimeUtils::US_TIMEZONES) ? LETTER_SIZE : A4_SIZE
    end

    def orientation_match?(size, image)
      return false if size.nil?

      (size[0] > size[1]) == (image.width > image.height)
    end

    def aspect_page_size(image)
      short, long = [image.width, image.height].minmax

      [LETTER_SIZE, A4_SIZE].find do |(page_short, page_long)|
        ((short * page_long) - (long * page_short)).abs <= page_short
      end
    end

    def scanned_page_image?(image)
      counts = image.colourspace('b-w').hist_find.to_a[0].flatten

      counts[SCAN_WHITE_THRESHOLD..].sum >= counts.sum * SCAN_WHITE_FRACTION
    end

    def build_pdf_data_from_image(attachment, pdf_size, default_size, redact: nil, rotate: nil)
      image = ImageUtils.load_vips(attachment.preview_images.first.download)

      image = image.colourspace(:srgb) if image.interpretation != :srgb
      image = image.flatten(background: 255) if image.has_alpha?
      image = draw_image_redaction(image, redact) if redact.present?
      image = rotate_vips_image(image, rotate.to_i)

      bitdepth = 2**image.stats.to_a[1..3].pluck(2).uniq.size

      png_data = image.write_to_buffer(Templates::ProcessDocument::FORMAT,
                                       compression: 6, filter: 0, bitdepth:, palette: true,
                                       Q: Templates::ProcessDocument::Q, dither: 0, strip: true)

      build_image_page_pdf(image, png_data, pdf_size, default_size)
    end

    def build_image_page_pdf(image, png_data, pdf_size, default_size)
      pdf_size = nil unless orientation_match?(pdf_size, image)
      aspect_size = aspect_page_size(image) if pdf_size.nil?

      page_width, page_height =
        pdf_size ||
        (aspect_size || default_size).then { |size| image.width > image.height ? size.reverse : size }

      scale = [page_width / image.width.to_f, page_height / image.height.to_f].min

      if pdf_size.nil? && aspect_size.nil? && !scanned_page_image?(image)
        Templates::BuildImagePagePdf.call(png_data, page_width: image.width * scale,
                                                    page_height: image.height * scale)
      else
        image_width = image.width * scale
        image_height = image.height * scale

        Templates::BuildImagePagePdf.call(png_data, page_width:, page_height:,
                                                    image_box: [(page_width - image_width) / 2.0,
                                                                (page_height - image_height) / 2.0,
                                                                image_width, image_height])
      end
    end

    def save_document(template, old_attachment, data)
      annotations = data.size < ANNOTATIONS_SIZE_LIMIT ? Templates::BuildAnnotations.call(data) : []
      sha256 = Base64.urlsafe_encode64(Digest::SHA256.digest(data))

      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(data),
        filename: "#{old_attachment.filename.base}.pdf",
        metadata: { identified: true, analyzed: true,
                    pdf: { annotations: }.compact_blank, sha256: }.compact_blank,
        content_type: Templates::ProcessDocument::PDF_CONTENT_TYPE
      )

      document = template.documents.create!(blob:)

      Templates::ProcessDocument.call(document, data)
    end

    def remap_fields(template, mapping)
      non_dynamic_uuids = template.schema.reject { |item| item['dynamic'] }.pluck('attachment_uuid')

      removed_field_uuids = []

      template.fields = template.fields.filter_map do |field|
        if field['areas'].present?
          field['areas'] = field['areas'].filter_map do |area|
            next area if non_dynamic_uuids.exclude?(area['attachment_uuid'])

            new_uuid, new_page, rotate = mapping[[area['attachment_uuid'], area['page']]]

            next if new_uuid.nil?

            rotate_area(area.merge('attachment_uuid' => new_uuid, 'page' => new_page), rotate.to_i)
          end

          if field['areas'].blank?
            removed_field_uuids << field['uuid']

            next
          end
        end

        field
      end

      removed_field_uuids
    end

    def rotate_area(area, rotate)
      x, y, w, h = area.values_at('x', 'y', 'w', 'h')

      case rotate
      when 90
        area.merge('x' => 1 - y - h, 'y' => x, 'w' => h, 'h' => w)
      when 180
        area.merge('x' => 1 - x - w, 'y' => 1 - y - h)
      when 270
        area.merge('x' => y, 'y' => 1 - x - w, 'w' => h, 'h' => w)
      else
        area
      end
    end

    def remove_conditions(items, removed_field_uuids)
      return if removed_field_uuids.blank?

      items.each do |item|
        next if item['conditions'].blank?

        item['conditions'] = item['conditions'].reject { |c| removed_field_uuids.include?(c['field_uuid']) }
      end
    end
  end
end
