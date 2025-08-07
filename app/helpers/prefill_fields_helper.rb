# frozen_string_literal: true

module PrefillFieldsHelper
  def extract_ats_prefill_fields
    return [] if params[:ats_fields].blank?

    begin
      decoded_json = Base64.urlsafe_decode64(params[:ats_fields])
      field_names = JSON.parse(decoded_json)

      # Validate that we got an array of strings
      return [] unless field_names.is_a?(Array) && field_names.all?(String)

      # Filter to only expected field name patterns
      valid_fields = field_names.select { |name| valid_ats_field_name?(name) }

      # Log successful field reception
      Rails.logger.info "Received #{valid_fields.length} ATS prefill fields: #{valid_fields.join(', ')}"

      valid_fields
    rescue StandardError => e
      Rails.logger.warn "Failed to parse ATS prefill fields: #{e.message}"
      []
    end
  end

  private

  def valid_ats_field_name?(name)
    # Only allow expected field name patterns (security)
    name.match?(/\A(employee|manager|account|location)_[a-z_]+\z/)
  end
end
