# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DIELCA initial setup' do
  it 'preselects Spanish without removing DocuSeal attribution' do
    get '/setup'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Portal de firmas', 'DocuSeal', 'Código fuente de esta versión')
    expect(response.body).to include('selected="selected" value="es-ES"')
  end
end
