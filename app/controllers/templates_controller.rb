# frozen_string_literal: true

class TemplatesController < ApplicationController
  layout false

  def show
    @template = current_account.templates.preload(documents_attachments: { preview_images_attachments: :blob })
                               .find(params[:id])
  end

  def new
    @template = current_account.templates.new
  end

  def create
    @template = current_account.templates.new(template_params)
    @template.author = current_user

    if @template.save
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
end
