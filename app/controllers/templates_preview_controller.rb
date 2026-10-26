# frozen_string_literal: true

class TemplatesPreviewController < ApplicationController
  load_and_authorize_resource :template

  def show
    @template_data = Templates.serialize_for_builder(@template)

    render :show, layout: 'plain'
  end
end
