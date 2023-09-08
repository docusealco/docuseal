# frozen_string_literal: true

module Submitters
  module SubmitValues
    ValidationError = Class.new(StandardError)

    module_function

    def call(submitter, params, request)
      Submissions.update_template_fields!(submitter.submission) if submitter.submission.template_fields.blank?

      update_submitter!(submitter, params, request)

      submitter.submission.save!

      return submitter unless submitter.completed_at?

      ProcessSubmitterCompletionJob.perform_later(submitter)

      submitter
    end

    def update_submitter!(submitter, params, request)
      values = normalized_values(params)

      validate_values!(values, submitter, params)

      submitter.values.merge!(values)
      submitter.opened_at ||= Time.current

      if params[:completed] == 'true'
        submitter.completed_at = Time.current
        submitter.ip = request.remote_ip
        submitter.ua = request.user_agent
      end

      submitter.save!

      submitter
    end

    def normalized_values(params)
      params.fetch(:values, {}).to_unsafe_h.transform_values do |v|
        if params[:cast_boolean] == 'true'
          v == 'true'
        elsif params[:normalize_phone] == 'true'
          v.to_s.gsub(/[^0-9+]/, '')
        else
          v.is_a?(Array) ? v.compact_blank : v
        end
      end
    end

    def validate_values!(values, submitter, params)
      values.each do |key, value|
        field = submitter.submission.template_fields.find { |e| e['uuid'] == key }

        validate_value!(value, field, params)
      end
    end

    def validate_value!(_value, _field, _params)
      true
    end
  end
end
