# frozen_string_literal: true

module Api
  class FlowsController < ApiBaseController
    def update
      @flow = current_account.flows.find(params[:id])

      @flow.update!(flow_params)

      render :ok
    end

    private

    def flow_params
      params.require(:flow).permit(:name,
                                   schema: [%i[attachment_uuid name]],
                                   fields: [[:uuid, :name, :type, :required,
                                             { options: [], areas: [%i[x y w h attachment_uuid page]] }]])
    end
  end
end
