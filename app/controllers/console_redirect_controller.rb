# frozen_string_literal: true

class ConsoleRedirectController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def index
    params[:redir] = "#{Docuseal::CONSOLE_URL}/manage" if request.path == '/manage'

    return redirect_to(new_user_session_path({ redir: params[:redir] }.compact)) if true_user.blank?

    auth = JsonWebToken.encode(uuid: true_user.uuid,
                               scope: :console,
                               exp: 1.minute.from_now.to_i)

    redir_uri = Addressable::URI.parse(params[:redir])
    path = redir_uri.path if params[:redir].to_s.starts_with?(Docuseal::CONSOLE_URL)

    redirect_to "#{Docuseal::CONSOLE_URL}#{path}?#{{ **redir_uri&.query_values, 'auth' => auth }.to_query}",
                allow_other_host: true
  end
end
