# frozen_string_literal: true

class TemplatesVersionsController < ApplicationController
  load_and_authorize_resource :template

  def index
    versions = @template.template_versions.order(id: :desc).preload(:author)

    render json: versions.as_json(TemplateVersions::SERIALIZE_PARAMS)
  end

  def show
    version = @template.template_versions.find(params[:id])

    render json: TemplateVersions.serialize(version)
  end
end
