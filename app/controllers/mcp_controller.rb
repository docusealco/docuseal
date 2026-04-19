# frozen_string_literal: true

class McpController < ActionController::API
  before_action :authenticate_user!
  before_action :verify_mcp_enabled!

  before_action do
    authorize!(:manage, :mcp)
  end

  def call
    return head :ok if request.raw_post.blank?

    body = JSON.parse(request.raw_post)

    result = Mcp::HandleRequest.call(body, current_user, current_ability)

    if result
      render json: result
    else
      head :accepted
    end
  rescue CanCan::AccessDenied
    render json: { jsonrpc: '2.0', id: nil, error: { code: -32_603, message: 'Forbidden' } }, status: :forbidden
  rescue JSON::ParserError
    render json: { jsonrpc: '2.0', id: nil, error: { code: -32_700, message: 'Parse error' } }, status: :bad_request
  end

  private

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
