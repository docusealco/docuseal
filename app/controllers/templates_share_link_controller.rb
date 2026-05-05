# frozen_string_literal: true

class TemplatesShareLinkController < ApplicationController
  load_and_authorize_resource :template

  def show; end

  def create
    authorize!(:update, @template)

    @template.update!(template_params)

    if params[:redir].present? && params[:redir].start_with?('/')
      redirect_to params[:redir]
    else
      head :ok
    end
  end

  private

  def template_params
    params.require(:template).permit(:shared_link)
  end
end
