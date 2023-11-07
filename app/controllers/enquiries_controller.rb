# frozen_string_literal: true

class EnquiriesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def create
    if params[:talk_to_sales] == 'on'
      Faraday.post(Docuseal::ENQUIRIES_URL,
                   enquiry_params.merge(type: :talk_to_sales).to_json,
                   'Content-Type' => 'application/json')
    end

    head :ok
  end

  private

  def enquiry_params
    params.require(:user).permit(:email)
  end
end
