# frozen_string_literal: true

class ConsoleRedirectController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def index
    if request.path == '/upgrade'
      params[:redir] = Docuseal.multitenant? ? "#{Docuseal::CONSOLE_URL}/plans" : "#{Docuseal::CONSOLE_URL}/on_premises"
    end

    params[:redir] = "#{Docuseal::CONSOLE_URL}/manage" if request.path == '/manage'
    
    if request.path == '/sign_up'
      params[:redir] = Docuseal.multitenant? ? "#{Docuseal::CONSOLE_URL}/plans" : "#{Docuseal::CONSOLE_URL}/on_premises"
    end

    return redirect_to(new_user_session_path({ redir: params[:redir] }.compact)) if true_user.blank?

    # In development, if console URL is localhost and doesn't exist, redirect to cloud URL instead
    if Rails.env.development? && Docuseal::CONSOLE_URL.include?('localhost') && !Docuseal.multitenant?
      if params[:redir].to_s.include?('/on_premises')
        return redirect_to 'https://console.docuseal.com/on_premises', allow_other_host: true
      elsif params[:redir].to_s.include?('/plans')
        return redirect_to 'https://console.docuseal.com/plans', allow_other_host: true
      end
    end

    auth = JsonWebToken.encode(uuid: true_user.uuid,
                               scope: :console,
                               exp: 1.minute.from_now.to_i)

    redir_uri = Addressable::URI.parse(params[:redir])
    path = redir_uri.path if params[:redir].to_s.starts_with?(Docuseal::CONSOLE_URL)

    query_values = redir_uri&.query_values || {}
    redirect_to "#{Docuseal::CONSOLE_URL}#{path}?#{{ **query_values, 'auth' => auth }.to_query}",
                allow_other_host: true
  end
end
