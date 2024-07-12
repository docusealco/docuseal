# frozen_string_literal: true

module Templates
  module FindAcroFields
    PDF_CONTENT_TYPE = 'application/pdf'

    FIELD_NAME_REGEXP = /\A(?=.*\p{L})[\p{L}\d\s-]+\z/
    SKIP_FIELD_DESCRIPTION = %w[undefined].freeze

    module_function

    # rubocop:disable Metrics
    def call(pdf, attachment)
      return [] unless pdf.acro_form

      fields, annots_index = build_fields_with_pages(pdf)

      fields.filter_map do |field|
        areas = Array.wrap(field[:Kids] || field).filter_map do |child_field|
          page = annots_index[child_field.hash]

          media_box = page[:CropBox] || page[:MediaBox]
          crop_box = page[:CropBox] || media_box

          media_box_start = [media_box[0], media_box[1]]
          crop_shift = [crop_box[0] - media_box[0], crop_box[1] - media_box[1]]

          x0, y0, x1, y1 = child_field[:Rect]

          x0, y0 = correct_coordinates(x0, y0, crop_shift, media_box_start)
          x1, y1 = correct_coordinates(x1, y1, crop_shift, media_box_start)

          page_width = media_box[2] - media_box[0]
          page_height = media_box[3] - media_box[1]

          x = x0
          y = y0
          w = x1 - x0
          h = y1 - y0

          transformed_y = page_height - y - h

          attrs = {
            page: page.index,
            x: x / page_width.to_f,
            y: transformed_y / page_height.to_f,
            w: w / page_width.to_f,
            h: h / page_height.to_f,
            attachment_uuid: attachment.uuid
          }

          next if attrs[:w].zero? || attrs[:h].zero?

          if child_field[:MaxLen] && child_field.try(:concrete_field_type) == :comb_text_field
            attrs[:cell_w] = w / page_width / child_field[:MaxLen].to_f
          end

          attrs
        end

        next if areas.blank?

        field_properties = build_field_properties(field)

        next if field_properties.blank?
        next if field_properties[:default_value].present?

        if field_properties[:type].in?(%w[radio multiple])
          if areas.size != field_properties[:options].size
            field_properties[:options] = build_options(Array.new(areas.size, ''))
          end

          areas.each_with_index do |area, index|
            area[:option_uuid] = field_properties[:options][index][:uuid]
          end
        end

        {
          uuid: SecureRandom.uuid,
          required: false,
          preferences: {},
          areas:,
          **field_properties
        }
      end
    rescue StandardError => e
      raise if Rails.env.local?

      Rollbar.error(e) if defined?(Rollbar)

      []
    end

    def correct_coordinates(x_coord, y_coord, shift, media_box_start)
      corrected_x = x_coord + shift[0] - media_box_start[0]
      corrected_y = y_coord + shift[1] - media_box_start[1]

      [corrected_x, corrected_y]
    end

    def build_field_properties(field)
      field_name = field.full_field_name if field.full_field_name.to_s.match?(FIELD_NAME_REGEXP)

      field_name = field_name&.encode('utf-8', invalid: :replace, undef: :replace, replace: '')

      attrs = { name: field_name.to_s }
      attrs[:description] = field[:TU] if field[:TU].present? &&
                                          field[:TU] != field.full_field_name &&
                                          !field[:TU].in?(SKIP_FIELD_DESCRIPTION)

      if field.field_type == :Btn && field.concrete_field_type == :radio_button && field[:Opt].present?
        selected_option_index = (field.allowed_values || []).find_index(field.field_value)
        selected_option = field[:Opt][selected_option_index] if selected_option_index

        {
          **attrs,
          type: 'radio',
          options: build_options(field[:Opt], 'radio'),
          default_value: selected_option
        }
      elsif field.field_type == :Btn && field.concrete_field_type == :check_box &&
            field[:Kids].present? && field[:Kids].size > 1 && field.allowed_values.size > 1
        selected_option = (field.allowed_values || []).find { |v| v == field.field_value }

        return {} if field.allowed_values.include?(:BBox)

        {
          **attrs,
          type: 'radio',
          options: build_options(field.allowed_values, 'radio'),
          default_value: selected_option
        }
      elsif field.field_type == :Btn && field.concrete_field_type == :check_box
        {
          **attrs,
          type: 'checkbox',
          default_value: field.field_value.present?
        }
      elsif field.field_type == :Ch &&
            %i[combo_box editable_combo_box].include?(field.concrete_field_type) && field[:Opt].present?
        {
          **attrs,
          type: 'select',
          options: build_options(field[:Opt]),
          default_value: field.field_value
        }
      elsif field.field_type == :Ch && field.concrete_field_type == :multi_select && field[:Opt].present?
        {
          **attrs,
          type: 'multiple',
          options: build_options(field[:Opt], 'multiple'),
          default_value: field.field_value
        }
      elsif field.field_type == :Tx && field.concrete_field_type == :comb_text_field
        {
          **attrs,
          type: 'cells',
          default_value: field.field_value
        }
      elsif field.field_type == :Tx
        {
          **attrs,
          type: 'text',
          default_value: field.field_value
        }
      elsif field.field_type == :Sig
        {
          **attrs,
          type: 'signature'
        }
      else
        {}
      end.compact
    end

    def build_options(values, type = nil)
      is_skip_single_value = type.in?(%w[radio multiple]) && values.uniq.size == 1

      values.map do |option|
        is_option_number = option.is_a?(Symbol) && option.to_s.match?(/\A\d+\z/)

        option = option.encode('utf-8', invalid: :replace, undef: :replace, replace: '') if option.is_a?(String)

        {
          uuid: SecureRandom.uuid,
          value: is_option_number || is_skip_single_value ? '' : option
        }
      end
    end

    def build_fields_with_pages(pdf)
      fields_index = {}
      annots_index = {}

      pdf.pages.each do |page|
        page.each_annotation do |annot|
          annots_index[annot.hash] = page

          if !annot.key?(:Parent) && annot.key?(:FT)
            fields_index[annot.hash] ||= HexaPDF::Type::AcroForm::Field.wrap(pdf, annot)
          elsif annot.key?(:Parent)
            field = annot[:Parent]
            field = field[:Parent] while field[:Parent]

            fields_index[field.hash] ||= HexaPDF::Type::AcroForm::Field.wrap(pdf, field)
          end
        end
      end

      [process_fields_array(pdf, fields_index.values), annots_index]
    end

    def process_fields_array(pdf, array, acc = [])
      array.each_with_index do |field, index|
        next if field.nil?

        unless field.respond_to?(:type) && field.type == :XXAcroFormField
          array[index] = field = HexaPDF::Type::AcroForm::Field.wrap(pdf, field)
        end

        if field.terminal_field?
          acc << field
        else
          process_fields_array(pdf, field[:Kids], acc)
        end
      end

      acc
    end
    # rubocop:enable Metrics
  end
end
