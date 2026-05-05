# frozen_string_literal: true

module Templates
  module FindTextTags
    TAG_REGEXP = /\{\{([^{}]+)\}\}/
    TRUE_VALUES = [true, 'true', '1', 1].freeze
    FALSE_VALUES = [false, 'false', '0', 0].freeze

    module_function

    def call(data)
      tags = []

      Pdfium::Document.open_bytes(data) do |doc|
        doc.page_count.times do |page_index|
          page = doc.get_page(page_index)

          tags.concat(extract_page_tags(page, page_index))
        ensure
          page&.close
        end
      end

      tags
    end

    def extract_page_tags(page, page_index)
      group_text_nodes_by_line(page.text_nodes).flat_map do |line_nodes|
        text = line_nodes.map(&:content).join

        text.to_enum(:scan, TAG_REGEXP).filter_map do
          match = Regexp.last_match
          tag_nodes = line_nodes[match.begin(0)...match.end(0)]

          next if tag_nodes.blank?

          attrs = parse_tag(match[1])

          next if attrs.blank?

          area = build_area(tag_nodes, page_index)

          {
            field: build_field(attrs, area),
            area: area
          }
        end
      end
    end

    def group_text_nodes_by_line(text_nodes)
      lines = text_nodes.each_with_object([]) do |node, items|
        line = items.find { |line_items| same_line?(line_items.first, node) }

        if line
          line << node
        else
          items << [node]
        end
      end

      lines.map { |line| line.sort_by(&:x) }
    end

    def same_line?(first_node, second_node)
      (first_node.endy - second_node.endy).abs < [first_node.h, second_node.h].max
    end

    def parse_tag(text)
      parts = text.split(';').map(&:strip).compact_blank
      name = parts.shift

      return if name.blank?

      attrs = { 'name' => name }

      parts.each do |part|
        key, value = part.split('=', 2).map(&:strip)

        next if key.blank?

        attrs[key.tr('-', '_').downcase] = cast_value(value)
      end

      attrs
    end

    def cast_value(value)
      return true if value.nil?
      return true if TRUE_VALUES.include?(value)
      return false if FALSE_VALUES.include?(value)

      value
    end

    def build_area(nodes, page_index)
      x1 = nodes.map(&:x).min
      y1 = nodes.map(&:y).min
      x2 = nodes.map(&:endx).max
      y2 = nodes.map(&:endy).max

      {
        'x' => x1,
        'y' => y1,
        'w' => x2 - x1,
        'h' => y2 - y1,
        'page' => page_index
      }
    end

    def build_field(attrs, area)
      preferences = build_preferences(attrs)

      {
        'uuid' => attrs['uuid'].presence || SecureRandom.uuid,
        'name' => attrs['name'],
        'role' => attrs['role'],
        'type' => attrs['type'].presence || 'text',
        'required' => attrs.key?('required') ? attrs['required'] : true,
        'readonly' => attrs['readonly'],
        'title' => attrs['title'],
        'description' => attrs['description'],
        'default_value' => attrs['default_value'] || attrs['value'],
        'preferences' => preferences,
        'options' => build_options(attrs),
        'areas' => [area]
      }.compact
    end

    def build_preferences(attrs)
      attrs.slice('font_size', 'font_type', 'font', 'color', 'background', 'align', 'valign', 'format',
                  'price', 'currency', 'mask', 'reasons').compact_blank
    end

    def build_options(attrs)
      values = attrs['options'] || attrs['values']

      values.to_s.split(',').map(&:strip).compact_blank.map do |value|
        { 'value' => value, 'uuid' => SecureRandom.uuid }
      end.presence
    end
  end
end
