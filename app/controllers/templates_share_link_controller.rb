# frozen_string_literal: true

class TemplatesShareLinkController < ApplicationController
  load_and_authorize_resource :template

  def show; end

  def create
    authorize!(:update, @template)

    @template.update!(template_params)

    head :ok
  end

  private

  def template_params
    params.require(:template).permit(:shared_link)
  end
end
