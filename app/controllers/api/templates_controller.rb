# frozen_string_literal: true

module Api
  class TemplatesController < ApiBaseController
    def update
      @template = current_account.templates.find(params[:id])

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
