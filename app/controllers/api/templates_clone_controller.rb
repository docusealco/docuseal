# frozen_string_literal: true

module Api
  class TemplatesCloneController < ApiBaseController
    load_and_authorize_resource :template

    def create
      authorize!(:manage, @template)

      template = current_account.templates.new(source: :api)

      template.application_key = params[:application_key]
      template.name = params[:name] || "#{@template.name} (Clone)"
      template.account = @template.account
      template.author = current_user
      template.assign_attributes(@template.slice(:folder_id, :fields, :schema, :submitters))

      if params[:folder_name].present?
        template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
      end

      template.save!

      Templates::CloneAttachments.call(template:, original_template: @template)

      render json: template.as_json(serialize_params)
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
