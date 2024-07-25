# frozen_string_literal: true

class TemplatesController < ApplicationController
  load_and_authorize_resource :template

  before_action :load_base_template, only: %i[new create]

  def show
    submissions = @template.submissions.accessible_by(current_ability)
    submissions = submissions.active if @template.archived_at.blank?
    submissions = Submissions.search(submissions, params[:q], search_values: true)

    @base_submissions = submissions

    submissions = submissions.pending if params[:status] == 'pending'
    submissions = submissions.completed if params[:status] == 'completed'

    @pagy, @submissions = pagy(submissions.preload(:submitters).order(id: :desc))
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end

  def new
    @template.name = "#{@base_template.name} (Clone)" if @base_template
  end

  def edit
    ActiveRecord::Associations::Preloader.new(
      records: [@template],
      associations: [schema_documents: [:blob, { preview_images_attachments: :blob }]]
    ).call

    @template_data =
      @template.as_json.merge(
        documents: @template.schema_documents.as_json(
          methods: %i[metadata signed_uuid],
          include: { preview_images: { methods: %i[url metadata filename] } }
        )
      ).to_json

    render :edit, layout: 'plain'
  end

  def create
    if @base_template
      ActiveRecord::Associations::Preloader.new(
        records: [@base_template],
        associations: [schema_documents: :preview_images_attachments]
      ).call

      @template = Templates::Clone.call(@base_template, author: current_user,
                                                        name: params.dig(:template, :name),
                                                        folder_name: params[:folder_name])
    else
      @template.author = current_user
      @template.folder = TemplateFolders.find_or_create_by_name(current_user, params[:folder_name])
    end

    if params[:account_id].present? && authorized_clone_account_id?(params[:account_id])
      @template.account_id = params[:account_id]
      @template.folder = @template.account.default_template_folder if @template.account_id != current_account.id
    else
      @template.account = current_account
    end

    if @template.save
      Templates::CloneAttachments.call(template: @template, original_template: @base_template) if @base_template

      SendTemplateUpdatedWebhookRequestJob.perform_async('template_id' => @template.id)

      maybe_redirect_to_template(@template)
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'templates/new'), status: :unprocessable_entity
    end
  end

  def update
    @template.update!(template_params)

    SendTemplateUpdatedWebhookRequestJob.perform_async('template_id' => @template.id)

    head :ok
  end

  def destroy
    notice =
      if params[:permanently].present?
        @template.destroy!

        'Template has been removed.'
      else
        @template.update!(archived_at: Time.current)

        'Template has been archived.'
      end

    redirect_back(fallback_location: root_path, notice:)
  end

  private

  def template_params
    params.require(:template).permit(
      :name,
      { schema: [%i[attachment_uuid name]],
        submitters: [%i[name uuid]],
        fields: [[:uuid, :submitter_uuid, :name, :type,
                  :required, :readonly, :default_value,
                  :title, :description,
                  { preferences: {},
                    conditions: [%i[field_uuid value action]],
                    options: [%i[value uuid]],
                    validation: %i[message pattern],
                    areas: [%i[x y w h cell_w attachment_uuid option_uuid page]] }]] }
    )
  end

  def authorized_clone_account_id?(account_id)
    true_user.account_id.to_s == account_id.to_s || true_user.account.linked_accounts.exists?(id: account_id)
  end

  def maybe_redirect_to_template(template)
    if template.account == current_account
      redirect_to(edit_template_path(@template))
    else
      redirect_back(fallback_location: root_path, notice: 'Template has been clonned')
    end
  end

  def load_base_template
    return if params[:base_template_id].blank?

    @base_template = Template.accessible_by(current_ability).find_by(id: params[:base_template_id])
  end
end
