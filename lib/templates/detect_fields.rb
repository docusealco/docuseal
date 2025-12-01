# frozen_string_literal: true

module Templates
  module DetectFields
    module_function

    TextFieldBox = Struct.new(:x, :y, :w, :h, keyword_init: true) do
      def endy
        @endy ||= y + h
      end

      def endx
        @endx ||= x + w
      end
    end

    PageNode = Struct.new(:prev, :next, :elem, :page, :attachment_uuid, keyword_init: true)

    DATE_REGEXP = /
      (?:
          date
        | signed\sat
        | datum
      )[:_\s-]*\z
    /ix

    NUMBER_REGEXP = /
      (?:
          price
        | \$
        | €
        | total
        | quantity
        | prix
        | quantité
        | preis
        | summe
        | gesamt(?:betrag)?
        | menge
        | anzahl
        | stückzahl
      )[:_\s-]*\z
    /ix

    SIGNATURE_REGEXP = /
      (?:
          signature
        | sign\shere
        | sign
        | signez\sici
        | signer\sici
        | unterschrift
        | unterschreiben
        | unterzeichnen
      )[:_\s-]*\z
    /ix

    LINEBREAK = ["\n", "\r"].freeze
    CHECKBOXES = ['☐', '□'].freeze

    # rubocop:disable Metrics, Style
    def call(io, attachment: nil, confidence: 0.3, temperature: 1, inference: Templates::ImageToFields,
             nms: 0.1, split_page: false, aspect_ratio: true, padding: 20, regexp_type: true, &)
      fields, head_node =
        if attachment&.image?
          process_image_attachment(io, attachment:, confidence:, nms:, split_page:, inference:,
                                       temperature:, aspect_ratio:, padding:, &)
        else
          process_pdf_attachment(io, attachment:, confidence:, nms:, split_page:, inference:,
                                     temperature:, aspect_ratio:, regexp_type:, padding:, &)
        end

      [fields, head_node]
    end

    def process_image_attachment(io, attachment:, confidence:, nms:, temperature:, inference:,
                                 split_page: false, aspect_ratio: false, padding: nil)
      image = Vips::Image.new_from_buffer(io.read, '')

      fields = inference.call(image, confidence:, nms:, split_page:,
                                     temperature:, aspect_ratio:, padding:)

      fields = sort_fields(fields, y_threshold: 10.0 / image.height)

      fields = fields.map do |f|
        {
          uuid: SecureRandom.uuid,
          type: f.type,
          required: f.type == 'signature',
          preferences: {},
          areas: [{
            x: f.x,
            y: f.y,
            w: f.w,
            h: f.h,
            page: 0,
            attachment_uuid: attachment&.uuid
          }]
        }
      end

      yield [attachment&.uuid, 0, fields] if block_given?

      [fields, nil]
    end

    def process_pdf_attachment(io, attachment:, confidence:, nms:, temperature:, inference:,
                               split_page: false, aspect_ratio: false, padding: nil, regexp_type: false)
      doc = Pdfium::Document.open_bytes(io.read)

      head_node = PageNode.new(elem: ''.b, page: 0, attachment_uuid: attachment&.uuid)
      tail_node = head_node

      fields = doc.page_count.times.flat_map do |page_number|
        page = doc.get_page(page_number)

        data, width, height = page.render_to_bitmap(width: inference::RESOLUTION * 1.5)

        image = Vips::Image.new_from_memory(data, width, height, 4, :uchar)

        fields = inference.call(image, confidence: confidence / 4.0, nms:, split_page:,
                                       temperature:, aspect_ratio:, padding:)

        text_fields = extract_text_fields_from_page(page)
        line_fields = extract_line_fields_from_page(page)

        fields = sort_fields(fields, y_threshold: 10.0 / image.height)

        fields = increase_confidence_for_overlapping_fields(fields, text_fields)
        fields = increase_confidence_for_overlapping_fields(fields, line_fields)

        fields = fields.reject { |f| f.confidence < confidence }

        field_nodes, tail_node = build_page_nodes(page, fields, tail_node, attachment_uuid: attachment&.uuid)

        fields = field_nodes.map do |node|
          field = node.elem

          type = regexp_type ? type_from_page_node(node) : field.type

          {
            uuid: SecureRandom.uuid,
            type:,
            required: type == 'signature',
            preferences: {},
            areas: [{
              x: field.x, y: field.y,
              w: field.w, h: field.h,
              page: page_number,
              attachment_uuid: attachment&.uuid
            }]
          }
        end

        yield [attachment&.uuid, page_number, fields] if block_given?

        fields
      ensure
        page.close
      end

      print_debug(head_node) if Rails.env.development?

      [fields, head_node]
    ensure
      doc.close
    end

    def sort_fields(fields, y_threshold: 0.01)
      fields.sort do |a, b|
        (a.endy - b.endy).abs < y_threshold ? a.x <=> b.x : a.endy <=> b.endy
      end
    end

    def print_debug(head_node)
      current_node = head_node
      index = 0
      string = ''.b

      loop do
        string <<
          if current_node.elem.is_a?(String)
            current_node.elem
          else
            "[#{current_node.elem.type == 'checkbox' ? 'Checkbox' : 'Field'}_#{index += 1}]"
          end

        current_node = current_node.next

        break unless current_node
      end

      Rails.logger.info(string)
    end

    def type_from_page_node(node)
      return node.elem.type unless node.prev.elem.is_a?(String)
      return node.elem.type unless node.elem.type == 'text'

      string = node.prev.elem

      return 'date' if string.match?(DATE_REGEXP)
      return 'signature' if string.match?(SIGNATURE_REGEXP)
      return 'number' if string.match?(NUMBER_REGEXP)

      return 'text'
    end

    def build_page_nodes(page, fields, tail_node, attachment_uuid: nil)
      field_nodes = []

      y_threshold = 4.0 / page.height
      x_threshold = 30.0 / page.width

      text_nodes = page.text_nodes

      current_field = fields.shift

      index = 0

      prev_node = nil

      loop do
        node = text_nodes[index]

        break unless node

        if node.content.in?(LINEBREAK)
          next_node = text_nodes[index]

          if next_node && (next_node.endy - node.endy) < y_threshold
            index += 1

            next
          end
        end

        loop do
          break unless current_field

          if ((current_field.endy - node.endy).abs < y_threshold &&
              (current_field.x <= node.x || node.content.in?(LINEBREAK))) ||
             current_field.endy < node.y
            if tail_node.elem.is_a?(Templates::ImageToFields::Field)
              divider =
                if (tail_node.elem.endy - current_field.endy).abs > y_threshold
                  "\n".b
                elsif tail_node.elem.endx - current_field.x > x_threshold
                  "\t".b
                else
                  ' '.b
                end

              text_node = PageNode.new(prev: tail_node, elem: divider, page: page.page_index, attachment_uuid:)
              tail_node.next = text_node

              tail_node = text_node
            elsif prev_node && (prev_node.endy - current_field.endy).abs > y_threshold
              text_node = PageNode.new(prev: tail_node, elem: "\n".b, page: page.page_index, attachment_uuid:)
              tail_node.next = text_node

              tail_node = text_node
            end

            field_node = PageNode.new(prev: tail_node, elem: current_field, page: page.page_index, attachment_uuid:)

            tail_node.next = field_node
            tail_node = field_node
            field_nodes << tail_node

            current_field = fields.shift
          else
            break
          end
        end

        if tail_node.elem.is_a?(Templates::ImageToFields::Field)
          prev_field = tail_node.elem

          text_node = PageNode.new(prev: tail_node, elem: ''.b, page: page.page_index, attachment_uuid:)
          tail_node.next = text_node

          tail_node = text_node

          if (node.endy - prev_field.endy).abs > y_threshold
            tail_node.elem << "\n"
          elsif (node.x - prev_field.endx) > x_threshold
            tail_node.elem << "\t"
          end
        elsif prev_node
          if (node.endy - prev_node.endy) > y_threshold && LINEBREAK.exclude?(prev_node.content)
            tail_node.elem << "\n"
          elsif (node.x - prev_node.endx) > x_threshold && !tail_node.elem.ends_with?("\t")
            tail_node.elem << "\t"
          end
        end

        if node.content != '_' || !tail_node.elem.ends_with?('___')
          tail_node.elem << node.content unless CHECKBOXES.include?(node.content)
        end

        prev_node = node

        index += 1
      end

      loop do
        break unless current_field

        field_node = PageNode.new(prev: tail_node, elem: current_field, page: page.page_index, attachment_uuid:)
        tail_node.next = field_node
        tail_node = field_node
        field_nodes << tail_node

        current_field = fields.shift
      end

      if tail_node.elem.is_a?(Templates::ImageToFields::Field)
        text_node = PageNode.new(prev: tail_node, elem: "\n".b, page: page.page_index, attachment_uuid:)
        tail_node.next = text_node

        tail_node = text_node
      else
        tail_node.elem << "\n"
      end

      [field_nodes, tail_node]
    end

    def extract_line_fields_from_page(page)
      line_thickness = 5.0 / page.height

      vertical_lines, all_horizontal_lines = page.line_nodes.partition { |line| line.tilt == 90 }

      horizontal_lines = all_horizontal_lines.reject do |h_line|
        next true if h_line.w > 0.7 && (h_line.h < 0.1 || h_line.h < 0.9)

        next false if vertical_lines.blank?

        h_x_min = h_line.x
        h_x_max = h_line.x + h_line.w
        h_y_avg = h_line.y + (h_line.h / 2)

        vertical_lines.any? do |v_line|
          v_x_avg = v_line.x + (v_line.w / 2)
          v_y_min = v_line.y
          v_y_max = v_line.y + v_line.h

          h_x_min_expanded = h_x_min - line_thickness
          h_x_max_expanded = h_x_max + line_thickness
          h_y_min_expanded = h_y_avg - line_thickness
          h_y_max_expanded = h_y_avg + line_thickness

          v_x_min_expanded = v_x_avg - line_thickness
          v_x_max_expanded = v_x_avg + line_thickness
          v_y_min_expanded = v_y_min - line_thickness
          v_y_max_expanded = v_y_max + line_thickness

          x_overlap = v_x_min_expanded <= h_x_max_expanded && v_x_max_expanded >= h_x_min_expanded
          y_overlap = h_y_min_expanded <= v_y_max_expanded && h_y_max_expanded >= v_y_min_expanded

          x_overlap && y_overlap
        end
      end

      node_index = 0

      horizontal_lines = horizontal_lines.reject do |line|
        nodes = []

        loop do
          node = page.text_nodes[node_index += 1]

          break unless node

          break if node.y > line.y

          next if node.x + node.w < line.x || line.x + line.w < node.x ||
                  node.y + node.h < line.y - node.h || line.y < node.y

          nodes << node

          next if nodes.blank?

          next_node = page.text_nodes[node_index + 1]

          break unless next_node

          break if next_node.x + next_node.w < line.x || line.x + line.w < next_node.x ||
                   next_node.y + next_node.h < line.y - next_node.h || line.y < next_node.y
        end

        next if nodes.blank?

        width = nodes.last.x + nodes.last.w - nodes.first.x

        next true if width > line.w / 2.0
      end

      horizontal_lines.each do |line|
        line.h += 4 * line_thickness
        line.y -= 4 * line_thickness
      end
    end

    def extract_text_fields_from_page(page)
      text_nodes = page.text_nodes

      field_boxes = []

      i = 0

      while i < text_nodes.length
        node = text_nodes[i]

        next i += 1 if node.content != '_'

        x1 = node.x
        y1 = node.y
        x2 = node.endx
        y2 = node.endy

        underscore_count = 1

        j = i + 1

        while j < text_nodes.length
          next_node = text_nodes[j]

          break unless next_node.content == '_'

          distance = next_node.x - x2
          height_diff = (next_node.y - y1).abs

          break if distance > 0.02 || height_diff > node.h * 0.5

          underscore_count += 1

          next_x2 = next_node.endx
          next_y2 = next_node.endy

          x2 = next_x2
          y2 = [y2, next_y2].max
          y1 = [y1, next_node.y].min

          j += 1
        end

        field_boxes << TextFieldBox.new(x: x1, y: y1, w: x2 - x1, h: y2 - y1) if underscore_count >= 2

        i = j
      end

      field_boxes
    end

    def calculate_iou(box1, box2)
      x1 = [box1.x, box2.x].max
      y1 = [box1.y, box2.y].max
      x2 = [box1.endx, box2.endx].min
      y2 = [box1.endy, box2.endy].min

      intersection_width = [0, x2 - x1].max
      intersection_height = [0, y2 - y1].max
      intersection_area = intersection_width * intersection_height

      return 0.0 if intersection_area.zero?

      box1_area = box1.w * box1.h
      box2_area = box2.w * box2.h
      union_area = box1_area + box2_area - intersection_area

      intersection_area / union_area
    end

    def boxes_overlap?(box1, box2)
      !(box1.endx < box2.x || box2.endx < box1.x || box1.endy < box2.y || box2.endy < box1.y)
    end

    def increase_confidence_for_overlapping_fields(image_fields, text_fields, by: 1.0)
      return image_fields if text_fields.blank?

      image_fields.map do |image_field|
        next if image_field.type != 'text'

        text_fields.each do |text_field|
          break if text_field.y > image_field.endy

          next if text_field.endy < image_field.y

          next unless boxes_overlap?(image_field, text_field)
          next if calculate_iou(image_field, text_field) < 0.4

          break image_field.confidence += by
        end
      end

      image_fields
    end
    # rubocop:enable Metrics, Style
  end
end
