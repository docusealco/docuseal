# frozen_string_literal: true

class StartFormEmail2faSendController < ApplicationController
  around_action :with_browser_locale

  skip_before_action :authenticate_user!
  skip_authorization_check

  def create
    @template = Template.find_by!(slug: params[:slug])

    @submitter = @template.submissions.new(account_id: @template.account_id)
                          .submitters.new(**submitter_params, account_id: @template.account_id)

    Submitters.send_shared_link_email_verification_code(@submitter, request:)

    redir_params = { notice: I18n.t(:code_has_been_resent) } if params[:resend]

    redirect_to start_form_path(@template.slug, params: submitter_params.merge(email_verification: true)),
                **redir_params
  rescue Submitters::UnableToSendCode => e
    redirect_to start_form_path(@template.slug, params: submitter_params.merge(email_verification: true)),
                alert: e.message
  end

  private

  def submitter_params
    params.require(:submitter).permit(:name, :email, :phone)
  end
end
