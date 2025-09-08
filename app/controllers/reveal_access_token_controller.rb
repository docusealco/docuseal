# frozen_string_literal: true

class RevealAccessTokenController < ApplicationController
  def show
    authorize!(:manage, current_user.access_token)
  end

  def create
    authorize!(:manage, current_user.access_token)

    if current_user.valid_password?(params[:password])
      render turbo_stream: turbo_stream.replace(:access_token_container,
                                                partial: 'reveal_access_token/access_token',
                                                locals: { token: current_user.access_token.token })
    else
      render turbo_stream: turbo_stream.replace(:modal, template: 'reveal_access_token/show',
                                                        locals: { error_message: I18n.t('wrong_password') }),
             status: :unprocessable_content
    end
  end
end
