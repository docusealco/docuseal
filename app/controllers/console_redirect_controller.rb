# frozen_string_literal: true

class ConsoleRedirectController < ApplicationController
  def index
    auth = JsonWebToken.encode(uuid: current_user.uuid,
                               action: :sign_in,
                               exp: 1.minute.from_now.to_i)

    redirect_to("#{Docuseal::CONSOLE_URL}?#{{ auth: }.to_query}", allow_other_host: true)
  end
end
