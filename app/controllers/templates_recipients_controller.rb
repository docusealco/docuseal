# frozen_string_literal: true

class TemplatesRecipientsController < ApplicationController
  load_and_authorize_resource :template

  def create
    authorize!(:update, @template)

    @template.submitters =
      submitters_params.map { |s| s.reject { |_, v| v.is_a?(String) && v.blank? } }

    @template.save!

    render json: { submitters: @template.submitters }
  end

  private

  def submitters_params
    permit_params = { submitters: [%i[name uuid is_requester optional_invite_by_uuid
                                      invite_by_uuid linked_to_uuid email option]] }

    params.require(:template).permit(permit_params).fetch(:submitters, {}).values.filter_map do |s|
      next if s[:uuid].blank?

      if s[:is_requester] == '1' && s[:invite_by_uuid].blank? && s[:optional_invite_by_uuid].blank?
        s[:is_requester] = true
      else
        s.delete(:is_requester)
      end

      s.delete(:invite_by_uuid) if s[:invite_by_uuid].blank?
      s.delete(:optional_invite_by_uuid) if s[:optional_invite_by_uuid].blank?

      normalize_option_value(s)
    end
  end

  def normalize_option_value(attrs)
    option = attrs.delete(:option)

    if option.present?
      case option
      when 'is_requester'
        attrs[:is_requester] = true
      when 'not_set'
        attrs.delete(:is_requester)
        attrs.delete(:email)
        attrs.delete(:linked_to_uuid)
        attrs.delete(:invite_by_uuid)
        attrs.delete(:optional_invite_by_uuid)
      when /\Alinked_to_(.*)\z/
        attrs[:linked_to_uuid] = ::Regexp.last_match(-1)
      when /\Aoptional_invite_by_(.*)\z/
        attrs[:optional_invite_by_uuid] = ::Regexp.last_match(-1)
      when /\Ainvite_by_(.*)\z/
        attrs[:invite_by_uuid] = ::Regexp.last_match(-1)
      end
    end

    attrs
  end
end
