# frozen_string_literal: true

class TemplatesPrefillableFieldsController < ApplicationController
  PREFILLABLE_FIELD_TYPES = %w[text number cells date checkbox select radio phone].freeze

  load_and_authorize_resource :template

  def create
    authorize!(:update, @template)

    field = @template.fields.find { |f| f['uuid'] == params[:field_uuid] }

    if params[:prefillable] == 'false'
      field.delete('prefillable')
      field.delete('readonly')
    elsif params[:prefillable] == 'true'
      field['prefillable'] = true
      field['readonly'] = true
    end

    @template.save!

    render turbo_stream: turbo_stream.replace(:prefillable_fields_list, partial: 'list',
                                                                        locals: { template: @template })
  end
end
