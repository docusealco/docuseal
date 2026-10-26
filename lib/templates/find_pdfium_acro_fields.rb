# frozen_string_literal: true

module Templates
  module FindPdfiumAcroFields
    DATE_JS_PREFIX = 'AFDate_'
    SKIP_FIELD_TYPES = %i[unknown pushbutton].freeze
    TEXT_OPERATOR_REGEXP = /\bT[jJ]\b/

    FIELD_NAME_REGEXP = /\A(?=.*\p{L})[\p{L}\d\s-]+\z/
    SKIP_FIELD_DESCRIPTION = %w[undefined].freeze
    SELECT_PLACEHOLDER_REGEXP = /\b(
      Select      |
      Choose      |
      Wählen      |
      Auswählen   |
      Sélectionner|
      Choisir     |
      Seleccionar |
      Elegir      |
      Seleziona   |
      Scegliere   |
      Selecionar  |
      Escolher
    )\b/ix

    DATE_FORMAT_REGEXP = %r{[myd]{2,4}[-\\/\s.][myd]{2,4}[-\\/\s.][myd]{2,4}}i

    FIELD_ALIGNMENT = {
      0 => 'left',
      1 => 'center',
      2 => 'right'
    }.freeze

    module_function

    def call(attachment, doc, data)
      return [] if !doc.form? && data.exclude?('/Form')

      pages = {}
      widgets = []

      doc.page_count.times do |page_index|
        next if doc.annot_count(page_index).zero?

        page = doc.get_page(page_index)

        pages[page_index] = { box: page.box, rotation: page.rotation }

        page.annotations.each do |annotation|
          next unless annotation.widget? && annotation.rect?

          field = annotation.field

          next if field.nil? || field.type.in?(SKIP_FIELD_TYPES)

          widgets << annotation
        end
      end

      group_widgets(widgets).filter_map { |field_widgets| build_field(field_widgets, pages, attachment) }
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)

      raise if Rails.env.development?

      []
    end

    def group_widgets(widgets)
      widgets.group_by do |annotation|
        field = annotation.field

        if (field.control_count > 1 && field.own?) || field.detached? || (field.name.blank? && field.control_count <= 1)
          [:widget, annotation.page_index, annotation.index]
        else
          [:field, field.type, field.name]
        end
      end.values
    end

    def build_field(widgets, pages, attachment)
      widgets = widgets.sort_by.with_index { |annotation, index| [annotation.field.control_index, index] }

      areas = widgets.filter_map { |annotation| build_area(annotation, pages[annotation.page_index], attachment) }

      return if areas.blank?

      field_properties = build_field_properties(widgets)

      return if field_properties.blank?
      return if field_properties[:default_value].present?

      if field_properties[:type] == 'radio'
        if areas.size != field_properties[:options].size
          field_properties[:options] = build_options(Array.new(areas.size, ''))
        end

        areas.each_with_index do |area, index|
          area[:option_uuid] = field_properties[:options][index][:uuid]
        end
      end

      {
        uuid: SecureRandom.uuid,
        required: widgets.first.field.required?,
        preferences: {},
        areas:,
        **field_properties
      }
    end

    def build_area(annotation, page, attachment)
      x, y, w, h, page_width, page_height = Pdfium.transform_rect(annotation.bounds, **page)

      attrs = {
        page: annotation.page_index,
        x: x / page_width,
        y: y / page_height,
        w: w / page_width,
        h: h / page_height,
        attachment_uuid: attachment.uuid
      }

      return if attrs[:w].zero? || attrs[:h].zero?

      field = annotation.field

      attrs[:cell_w] = attrs[:w] / field.max_len if field.comb? && field.max_len.to_f.positive?

      attrs
    end

    def build_field_properties(widgets)
      field = widgets.first.field

      field_name = field.name if field.name.match?(FIELD_NAME_REGEXP)

      attrs = { name: field_name.to_s }
      attrs[:description] = field.alternate_name if field.alternate_name.present? &&
                                                    field.alternate_name != field.name &&
                                                    !field.alternate_name.in?(SKIP_FIELD_DESCRIPTION)

      case field.type
      when :checkbox, :radio
        build_button_properties(attrs, widgets)
      when :combobox
        build_select_properties(attrs, widgets.first)
      when :text
        build_text_properties(attrs, field)
      when :signature
        {
          **attrs,
          type: field.name.to_s.downcase.include?('initials') ? 'initials' : 'signature'
        }
      else
        {}
      end.compact
    end

    def build_button_properties(attrs, widgets)
      field = widgets.first.field
      options = widgets.find { |w| w.field.options.present? }&.field&.options.to_a
      checked = widgets.find { |w| w.field.checked? }
      export_values = widgets.filter_map { |w| w.field.export_value.presence }.uniq

      if field.type == :radio && options.present?
        {
          **attrs,
          type: 'radio',
          options: build_options(options, 'radio'),
          default_value: checked && options[checked.field.control_index]
        }
      elsif field.control_count > 1 && export_values.size > 1
        {
          **attrs,
          type: 'radio',
          options: build_options(export_values.map(&:to_sym), 'radio'),
          default_value: checked&.field&.export_value.presence
        }
      else
        {
          **attrs,
          type: 'checkbox',
          default_value: checked.present?
        }
      end
    end

    def build_select_properties(attrs, annotation)
      field = annotation.field

      return {} if field.options.blank?

      value = field.value.presence if renders_text?(annotation)

      {
        **attrs,
        type: 'select',
        options: build_options(field.options, 'select'),
        default_value: value.to_s.match?(SELECT_PLACEHOLDER_REGEXP) ? nil : value
      }
    end

    def renders_text?(annotation)
      appearance = annotation.page.with_annotation(annotation.index, &:appearance)

      appearance.to_s.match?(TEXT_OPERATOR_REGEXP)
    end

    def build_text_properties(attrs, field)
      preferences = { align: FIELD_ALIGNMENT.fetch(field.quadding.to_i, 'left') }

      attrs = { **attrs, preferences: }

      if field.comb?
        { **attrs, type: 'cells', default_value: field.value.presence }
      elsif date?(field)
        format = [field.format_js, field.keystroke_js].compact
                                                      .filter_map { |js| js[DATE_FORMAT_REGEXP] }
                                                      .first

        preferences[:format] = format.upcase if format

        { **attrs, type: 'date', default_value: field.value.presence }
      else
        { **attrs, type: 'text', default_value: field.value.presence }
      end
    end

    def date?(field)
      field.format_js.to_s.include?(DATE_JS_PREFIX) || field.keystroke_js.to_s.include?(DATE_JS_PREFIX)
    end

    def build_options(values, type = nil)
      is_skip_single_value = type.in?(%w[radio multiple]) && values.uniq.size == 1

      values.filter_map do |option|
        is_option_number = option.is_a?(Symbol) && option.to_s.match?(/\A\d+\z/)

        option = option[1] if option.is_a?(Array) && option.size == 2

        if option.is_a?(String) || option.is_a?(Symbol)
          option = option.to_s.encode('utf-8', invalid: :replace, undef: :replace, replace: '')
        end

        next if type == 'select' && option.to_s.match?(SELECT_PLACEHOLDER_REGEXP)

        {
          uuid: SecureRandom.uuid,
          value: is_option_number || is_skip_single_value ? '' : option.presence
        }
      end
    end
  end
end
