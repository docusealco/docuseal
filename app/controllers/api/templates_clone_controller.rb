# frozen_string_literal: true

module Api
  class TemplatesCloneController < ApiBaseController
    load_and_authorize_resource :template

    def create
      authorize!(:manage, @template)

      cloned_template = Templates::Clone.call(
        @template,
        author: current_user,
        name: params[:name],
        external_id: params[:external_id].presence || params[:application_key],
        folder_name: params[:folder_name]
      )

      cloned_template.source = :api
      cloned_template.save!

      Templates::CloneAttachments.call(template: cloned_template, original_template: @template)

      render json: cloned_template.as_json(serialize_params)
    end

    private

    def serialize_params
      {
        include: { author: { only: %i[id email first_name last_name] },
                   documents: { only: %i[id uuid], methods: %i[url filename] } }
      }
    end
  end
end
