# frozen_string_literal: true

class FlowsController < ApplicationController
  def show
    @flow = current_account.flows.preload(documents_attachments: { preview_images_attachments: :blob })
                           .find(params[:id])
  end

  def new
    @flow = current_account.flows.new
  end

  def create
    @flow = current_account.flows.new(flow_params)
    @flow.author = current_user

    if @flow.save
      redirect_to flow_path(@flow)
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'flows/new'), status: :unprocessable_entity
    end
  end

  def destroy
    @flow = current_account.flows.find(params[:id])
    @flow.update!(deleted_at: Time.current)

    redirect_to settings_users_path, notice: 'Flow has been archived.'
  end

  private

  def flow_params
    params.require(:flow).permit(:name, :schema)
  end
end
