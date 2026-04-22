# frozen_string_literal: true

module Templates
  module FieldDetection
    module ConfigBased
      module_function

      def call(template, config, documents = nil)
        documents ||= template.schema_documents.preload(:blob)
        attachment = documents.first

        return [] unless attachment

        submitter_map = ensure_submitters(template, config)
        fields = build_fields(template, config, attachment, submitter_map)

        template.fields = fields
        template.save!

        fields
      end

      def ensure_submitters(template, config)
        submitter_map = {}
        config_submitters = config['submitters'] || []

        config_submitters.each do |cs|
          name = cs['name'].to_s.strip
          next if name.blank?

          existing = template.submitters.find { |s| s['name'].to_s.downcase == name.downcase }

          if existing
            submitter_map[name.downcase] = existing['uuid']
          else
            uuid = SecureRandom.uuid
            template.submitters << { 'name' => name, 'uuid' => uuid }
            submitter_map[name.downcase] = uuid
          end
        end

        submitter_map
      end

      def build_fields(template, config, attachment, submitter_map)
        config_fields = config['fields'] || []
        doc = Pdfium::Document.open_bytes(attachment.blob.download)
        page_texts = extract_page_texts(doc)

        config_fields.filter_map do |field_config|
          build_field(field_config, template, attachment, submitter_map, doc, page_texts)
        end
      ensure
        doc&.close
      end

      def build_field(field_config, template, attachment, submitter_map, doc, page_texts)
        submitter_key = field_config['submitter'].to_s.downcase.strip
        submitter_uuid = submitter_map[submitter_key] || template.submitters.first&.dig('uuid')

        return nil unless submitter_uuid

        area = resolve_area(field_config, doc, page_texts, attachment)

        return nil unless area

        {
          'uuid' => SecureRandom.uuid,
          'submitter_uuid' => submitter_uuid,
          'name' => field_config['name'].to_s,
          'type' => field_config['type'].to_s,
          'required' => field_config.fetch('required', true),
          'preferences' => field_config.fetch('preferences', {}),
          'areas' => [area]
        }
      end

      def resolve_area(field_config, doc, page_texts, attachment)
        if field_config['anchor']
          resolve_anchor_area(field_config, doc, page_texts, attachment)
        elsif field_config['position']
          resolve_absolute_area(field_config, doc, attachment)
        end
      end

      def resolve_anchor_area(field_config, doc, page_texts, attachment)
        anchor = field_config['anchor']
        anchor_text = anchor['text'].to_s
        anchor_page = anchor['page'] || 0
        area_config = field_config['area'] || {}

        resolved_page = resolve_page_index(anchor_page, doc.page_count)

        return nil unless resolved_page && resolved_page >= 0 && resolved_page < doc.page_count

        text_position = find_text_on_page(page_texts, resolved_page, anchor_text)

        return nil unless text_position

        {
          'attachment_uuid' => attachment.uuid,
          'page' => resolved_page,
          'x' => clamp(text_position[:x] + (area_config['x_offset'] || 0).to_f),
          'y' => clamp(text_position[:y] + (area_config['y_offset'] || 0).to_f),
          'w' => clamp_dimension(area_config['w'] || 0.25),
          'h' => clamp_dimension(area_config['h'] || 0.05)
        }
      end

      def resolve_absolute_area(field_config, doc, attachment)
        position = field_config['position']
        page_index = resolve_page_index(position['page'] || 0, doc.page_count)

        return nil unless page_index && page_index >= 0 && page_index < doc.page_count

        {
          'attachment_uuid' => attachment.uuid,
          'page' => page_index,
          'x' => clamp(position['x'].to_f),
          'y' => clamp(position['y'].to_f),
          'w' => clamp_dimension(position['w'] || 0.25),
          'h' => clamp_dimension(position['h'] || 0.05)
        }
      end

      def extract_page_texts(doc)
        (0...doc.page_count).map do |page_index|
          page = doc.get_page(page_index)
          nodes = page.text_nodes
          { nodes: nodes, page_index: page_index }
        ensure
          page&.close
        end
      end

      def find_text_on_page(page_texts, page_index, target_text)
        page_data = page_texts[page_index]

        return nil unless page_data

        target_lower = target_text.downcase

        accumulated = ''
        first_node = nil

        page_data[:nodes].each do |node|
          first_node = node if accumulated.empty?

          accumulated += node.content

          return { x: first_node.x, y: first_node.y } if accumulated.downcase.include?(target_lower)

          accumulated = '' if accumulated.length > target_text.length * 3
          first_node = nil if accumulated.empty?
        end

        nil
      end

      def resolve_page_index(page, total_pages)
        return nil if total_pages.zero?

        page = page.to_i
        page >= 0 ? page : total_pages + page
      end

      def clamp(value)
        value.to_f.clamp(0.0, 1.0)
      end

      def clamp_dimension(value)
        value.to_f.clamp(0.001, 1.0)
      end
    end
  end
end
