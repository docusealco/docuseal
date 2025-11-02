# frozen_string_literal: true

module Templates
  module DetectFields
    module_function

    TextFieldBox = Struct.new(:x, :y, :w, :h, keyword_init: true)

    # rubocop:disable Metrics
    def call(io, attachment: nil, confidence: 0.3, temperature: 1,
             nms: 0.1, split_page: false, aspect_ratio: true, padding: 20, &)
      if attachment&.image?
        process_image_attachment(io, attachment:, confidence:, nms:, split_page:,
                                     temperature:, aspect_ratio:, padding:, &)
      else
        process_pdf_attachment(io, attachment:, confidence:, nms:, split_page:,
                                   temperature:, aspect_ratio:, padding:, &)
      end
    end

    def process_image_attachment(io, attachment:, confidence:, nms:, temperature: 1,
                                 split_page: false, aspect_ratio: false, padding: nil)
      image = Vips::Image.new_from_buffer(io.read, '')

      fields = Templates::ImageToFields.call(image, confidence:, nms:, split_page:,
                                                    temperature:, aspect_ratio:, padding:)

      fields = fields.map do |f|
        {
          uuid: SecureRandom.uuid,
          type: f.type,
          required: true,
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

      fields
    end

    def process_pdf_attachment(io, attachment:, confidence:, nms:, temperature: 1,
                               split_page: false, aspect_ratio: false, padding: nil)
      doc = Pdfium::Document.open_bytes(io.read)

      doc.page_count.times.flat_map do |page_number|
        page = doc.get_page(page_number)

        data, width, height = page.render_to_bitmap(width: ImageToFields::RESOLUTION * 1.5)

        image = Vips::Image.new_from_memory(data, width, height, 4, :uchar)

        fields = Templates::ImageToFields.call(image, confidence: 0.05, nms:, split_page:,
                                                      temperature:, aspect_ratio:, padding:)

        text_fields = extract_text_fields_from_page(page)
        line_fields = extract_line_fields_from_page(page)

        fields = increase_confidence_for_overlapping_fields(fields, text_fields)
        fields = increase_confidence_for_overlapping_fields(fields, line_fields)

        fields = fields.filter_map do |f|
          next if f.confidence < confidence

          {
            uuid: SecureRandom.uuid,
            type: f.type,
            required: true,
            preferences: {},
            areas: [{
              x: f.x, y: f.y,
              w: f.w, h: f.h,
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
    ensure
      doc.close
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
        x2 = node.x + node.w
        y2 = node.y + node.h

        underscore_count = 1

        j = i + 1

        while j < text_nodes.length
          next_node = text_nodes[j]

          break unless next_node.content == '_'

          distance = next_node.x - x2
          height_diff = (next_node.y - y1).abs

          break if distance > 0.02 || height_diff > node.h * 0.5

          underscore_count += 1
          next_x2 = next_node.x + next_node.w
          next_y2 = next_node.y + next_node.h

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
      x2 = [box1.x + box1.w, box2.x + box2.w].min
      y2 = [box1.y + box1.h, box2.y + box2.h].min

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
      !(box1.x + box1.w < box2.x || box2.x + box2.w < box1.x ||
        box1.y + box1.h < box2.y || box2.y + box2.h < box1.y)
    end

    def increase_confidence_for_overlapping_fields(image_fields, text_fields, by: 1.0)
      return image_fields if text_fields.blank?

      image_fields.map do |image_field|
        next if image_field.type != 'text'

        field_bottom = image_field.y + image_field.h

        text_fields.each do |text_field|
          break if text_field.y > field_bottom

          next if text_field.y + text_field.h < image_field.y

          next unless boxes_overlap?(image_field, text_field) && calculate_iou(image_field, text_field) > 0.5

          break image_field.confidence += by
        end
      end

      image_fields
    end
    # rubocop:enable Metrics
  end
end
