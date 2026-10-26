# frozen_string_literal: true

module Mcp
  class McpBaseController < ActionController::API
    wrap_parameters false

    before_action :authenticate_user!
    before_action :verify_mcp_enabled!
    check_authorization

    before_action do
      raise CanCan::AccessDenied unless can?(:manage, :mcp)
    end

    rescue_from CanCan::AccessDenied do
      render_error(-32_603, 'Forbidden', status: :forbidden)
    end

    rescue_from ActiveRecord::RecordNotFound do
      render_tool_error('Not found')
    end

    private

    def default_url_options
      Docuseal.default_url_options
    end

    def mcp_body
      request.request_parameters
    end

    def mcp_params
      mcp_body.dig('params', 'arguments') || {}
    end

    def render_result(result)
      render json: { jsonrpc: '2.0', id: mcp_body['id'], result: }
    end

    def render_error(code, message, id: nil, status: :ok)
      render json: { jsonrpc: '2.0', id:, error: { code:, message: } }, status:
    end

    def render_tool_result(data)
      render_result(content: [{ type: 'text', text: data.to_json }])
    end

    def render_tool_error(message)
      render_result(content: [{ type: 'text', text: message }], isError: true)
    end

    def authenticate_user!
      return if current_user

      response.headers['WWW-Authenticate'] =
        %(Bearer resource_metadata="#{request.base_url}/.well-known/oauth-protected-resource", error="invalid_token")
      render json: { error: 'Not authenticated' }, status: :unauthorized
    end

    def verify_mcp_enabled!
      return if Docuseal.multitenant?

      return if AccountConfig.exists?(account_id: current_user.account_id,
                                      key: AccountConfig::ENABLE_MCP_KEY,
                                      value: true)

      render json: { error: 'MCP is disabled' }, status: :forbidden
    end

    def current_user
      @current_user ||= user_from_oauth_token || user_from_mcp_token
    end

    def user_from_oauth_token
      return if bearer_token.blank?

      access_token = Doorkeeper::AccessToken.by_token(bearer_token)
      return if access_token.nil? || access_token.revoked? || access_token.expired?
      return unless access_token.scopes.exists?('mcp')

      User.active.find_by(id: access_token.resource_owner_id)
    end

    def user_from_mcp_token
      return if bearer_token.blank?

      sha256 = Digest::SHA256.hexdigest(bearer_token)

      User.joins(:mcp_tokens).active.find_by(mcp_tokens: { sha256:, archived_at: nil })
    end

    def bearer_token
      @bearer_token ||= request.headers['Authorization'].to_s[/\ABearer\s+(.+)\z/, 1]
    end
  end
end
