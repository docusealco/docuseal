# frozen_string_literal: true

class TemplatesController < ApplicationController
  layout false

  before_action :load_base_template, only: %i[new create]

  def show
    @template = current_account.templates.preload(documents_attachments: { preview_images_attachments: :blob })
                               .find(params[:id])
  end

  def new
    @template = current_account.templates.new
    @template.name = "#{@base_template.name} (Clone)" if @base_template
  end

  def create
    @template =
      if @base_template
        current_account.templates.new(**@base_template.slice(:fields, :schema, :submitters), **template_params)
      else
        current_account.templates.new(template_params)
      end

    @template.author = current_user

    if @template.save
      Templates::CloneAttachments.call(template: @template, original_template: @base_template) if @base_template

      redirect_to template_path(@template)
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'templates/new'), status: :unprocessable_entity
    end
  end

  def destroy
    @template = current_account.templates.find(params[:id])
    @template.update!(deleted_at: Time.current)

    redirect_to settings_users_path, notice: 'template has been archived.'
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
