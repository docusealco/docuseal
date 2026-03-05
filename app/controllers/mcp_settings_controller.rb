# frozen_string_literal: true

class McpSettingsController < ApplicationController
  load_and_authorize_resource :mcp_token, parent: false

  before_action do
    authorize!(:manage, :mcp)
  end

  def index
    @mcp_tokens = @mcp_tokens.active.order(id: :desc)
  end

  def create
    @mcp_token = current_user.mcp_tokens.new(mcp_token_params)

    if @mcp_token.save
      @mcp_tokens = [@mcp_token]

      render :index, status: :created
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'mcp_settings/new'), status: :unprocessable_content
    end
  end

  def destroy
    @mcp_token.update!(archived_at: Time.current)

    redirect_back fallback_location: settings_mcp_index_path, notice: I18n.t('mcp_token_has_been_removed')
  end

  private

  def mcp_token_params
    params.require(:mcp_token).permit(:name)
  end
end
