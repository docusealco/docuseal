# frozen_string_literal: true

module Api
  class TemplatesCloneController < ApiBaseController
    load_and_authorize_resource :template

    def create
      authorize!(:create, @template)

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

      schema_documents = Templates::CloneAttachments.call(template: cloned_template,
                                                          original_template: @template,
                                                          documents: params[:documents])

      cloned_template.save!

      WebhookUrls.for_account_id(cloned_template.account_id, 'template.created').each do |webhook_url|
        SendTemplateCreatedWebhookRequestJob.perform_async('template_id' => cloned_template.id,
                                                           'webhook_url_id' => webhook_url.id)
      end

      SearchEntries.enqueue_reindex(cloned_template)

      render json: Templates::SerializeForApi.call(cloned_template, schema_documents)
    end
  end
end
