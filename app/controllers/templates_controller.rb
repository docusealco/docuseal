# frozen_string_literal: true

class TemplatesController < ApplicationController
  before_action :load_base_template, only: %i[new create]

  def show
    @template = current_account.templates.find(params[:id])

    @pagy, @submissions = pagy(@template.submissions.active)
  end

  def new
    @template = current_account.templates.new
    @template.name = "#{@base_template.name} (Clone)" if @base_template
  end

  def edit
    @template = current_account.templates.preload(documents_attachments: { preview_images_attachments: :blob })
                               .find(params[:id])

    render :edit, layout: 'plain'
  end

  def create
    @template = current_account.templates.new(template_params)
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
    @template = current_account.templates.find(params[:id])
    @template.update!(deleted_at: Time.current)

    redirect_back(fallback_location: root_path, notice: 'Template has been archived.')
  end

  private

  def template_params
    params.require(:template).permit(:name)
  end

  def load_base_template
    return if params[:base_template_id].blank?

    @base_template = current_account.templates
                                    .preload(documents_attachments: :preview_images_attachments)
                                    .find_by(id: params[:base_template_id])
  end
end
