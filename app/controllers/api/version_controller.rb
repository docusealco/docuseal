# frozen_string_literal: true

module Api
  class VersionController < ApiBaseController
    skip_before_action :authenticate_user!
    skip_authorization_check

    def show
      render json: { version: Docuseal.version }
    end
  end
end
