# frozen_string_literal: true

class TemplatesController < ApplicationController
  load_and_authorize_resource :template

  before_action :load_base_template, only: %i[new create]

  def show
    submissions = @template.submissions
    submissions = submissions.active if @template.deleted_at.blank?
    submissions = Submissions.search(submissions, params[:q])

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
      associations: [schema_documents: { preview_images_attachments: :blob }]
    ).call

    render :edit, layout: 'plain'
  end

  def create
    @template.account = current_account
    @template.author = current_user
    @template.assign_attributes(@base_template.slice(:fields, :schema, :submitters)) if @base_template

    if @template.save
      Templates::CloneAttachments.call(template: @template, original_template: @base_template) if @base_template

      redirect_to edit_template_path(@template)
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'templates/new'), status: :unprocessable_entity
    end
  end

  def destroy
    @template.update!(deleted_at: Time.current)

    redirect_back(fallback_location: root_path, notice: 'Template has been archived.')
  end

  private

  def template_params
    params.require(:template).permit(:name)
  end

  def load_base_template
    return if params[:base_template_id].blank?

    @base_template = current_account.templates.find_by(id: params[:base_template_id])
  end
end
