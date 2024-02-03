# frozen_string_literal: true

class TemplatesCodeModalController < ApplicationController
  load_and_authorize_resource :template

  def show; end
end
