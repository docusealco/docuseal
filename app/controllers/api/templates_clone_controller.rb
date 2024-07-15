# frozen_string_literal: true

module Api
  class TemplatesCloneController < ApiBaseController
    load_and_authorize_resource :template

    def create
      authorize!(:manage, @template)

      ActiveRecord::Associations::Preloader.new(
        records: [@template],
        associations: [schema_documents: :preview_images_attachments]
      ).call

      cloned_template = Templates::Clone.call(
        @template,
        author: current_user,
        name: params[:name],
        external_id: params[:external_id].presence || params[:application_key],
        folder_name: params[:folder_name]
      )

      cloned_template.source = :api
      cloned_template.save!

      schema_documents = Templates::CloneAttachments.call(template: cloned_template, original_template: @template)

      SendTemplateCreatedWebhookRequestJob.perform_async('template_id' => cloned_template.id)

      render json: Templates::SerializeForApi.call(cloned_template, schema_documents)
    end
  end
end
