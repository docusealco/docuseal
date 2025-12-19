# frozen_string_literal: true

module Submissions
  module NormalizeParamUtils
    module_function

    def normalize_submissions_params!(submissions_params, template, add_fields: false)
      attachments = []
      fields = []

      Array.wrap(submissions_params).each do |submission|
        submission[:submitters].each_with_index do |submitter, index|
          _, new_attachments, new_fields = normalize_submitter_params!(submitter, template, index, add_fields:)

          attachments.push(*new_attachments)
          fields.push(*new_fields)
        end
      end

      [submissions_params, attachments, fields]
    end

    def normalize_submitter_params!(submitter_params, template, index = nil, for_submitter: nil, add_fields: false)
      with_values = submitter_params[:values].present?

      default_values = with_values ? submitter_params[:values] : {}

      submitter_params[:fields]&.each do |f|
        default_values[f[:name].presence || f[:uuid]] = f[:default_value] if f.key?(:default_value)
        default_values[f[:name].presence || f[:uuid]] = f[:value] if f.key?(:value)
      end

      return submitter_params if default_values.blank?

      values, new_attachments, new_fields =
        Submitters::NormalizeValues.call(template,
                                         default_values,
                                         submitter_name: submitter_params[:role] ||
                                                         template.submitters.dig(index, 'name'),
                                         role_names: submitter_params[:roles],
                                         for_submitter:,
                                         add_fields:,
                                         throw_errors: !with_values)

      submitter_params[:values] = values

      [submitter_params, new_attachments, new_fields]
    end

    def save_default_value_attachments!(attachments, submitters)
      return if attachments.blank?

      attachments_index = attachments.index_by(&:uuid)

      submitters.each do |submitter|
        submitter.values.each_value do |value|
          Array.wrap(value).each do |v|
            attachment = attachments_index[v]

            next unless attachment

            attachment.record = submitter

            attachment.save!
          end
        end
      end
    end
  end
end
