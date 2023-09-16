# frozen_string_literal: true

module Api
  class TemplatesController < ApiBaseController
    load_and_authorize_resource :template

    def index
      render json: @templates
    end

    def show
      render json: @template.as_json(include: { author: { only: %i[id email first_name last_name] },
                                                documents: { only: %i[id uuid], methods: %i[url filename] } })
    end

    def update
      @template.update!(template_params)

      render :ok
    end

    private

    def template_params
      params.require(:template).permit(:name,
                                       schema: [%i[attachment_uuid name]],
                                       submitters: [%i[name uuid]],
                                       fields: [[:uuid, :submitter_uuid, :name, :type, :required,
                                                 { options: [], areas: [%i[x y w h cell_w attachment_uuid page]] }]])
    end
  end
end
