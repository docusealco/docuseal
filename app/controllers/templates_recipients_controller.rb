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
    params.require(:template).permit(
      submitters: [%i[name uuid is_requester invite_by_uuid linked_to_uuid email option]]
    ).fetch(:submitters, {}).values.filter_map do |s|
      next if s[:uuid].blank?

      if s[:is_requester] == '1' && s[:invite_by_uuid].blank?
        s[:is_requester] = true
      else
        s.delete(:is_requester)
      end

      s.delete(:invite_by_uuid) if s[:invite_by_uuid].blank?

      option = s.delete(:option)

      if option.present?
        case option
        when 'is_requester'
          s[:is_requester] = true
        when 'not_set'
          s.delete(:is_requester)
          s.delete(:email)
          s.delete(:linked_to_uuid)
          s.delete(:invite_by_uuid)
        when /\Alinked_to_(.*)\z/
          s[:linked_to_uuid] = ::Regexp.last_match(-1)
        when /\Ainvite_by_(.*)\z/
          s[:invite_by_uuid] = ::Regexp.last_match(-1)
        end
      end

      s
    end
  end
end
