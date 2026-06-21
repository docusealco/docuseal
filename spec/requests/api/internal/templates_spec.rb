# frozen_string_literal: true

describe 'Internal Templates API' do
  let(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:api_key) { user.access_token.token }

  def pdf_upload(name = 'sample-document.pdf')
    Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/sample-document.pdf'), 'application/pdf', false,
                                 original_filename: name)
  end

  describe 'POST /api/internal/templates' do
    it 'creates a template under the caller account from a single PDF' do
      expect do
        post '/api/internal/templates',
             params: { external_id: 'consent-1', files: [pdf_upload] },
             headers: { 'x-auth-token': api_key }
      end.to change(account.templates, :count).by(1)

      expect(response).to have_http_status(:ok)

      template = account.templates.find_by(external_id: 'consent-1')
      expect(template).to be_present
      expect(template.author).to eq(user)
      expect(template.documents.count).to eq(1)
      expect(response.parsed_body).to eq('id' => template.id, 'external_id' => 'consent-1')
    end

    it 'bundles multiple PDFs as documents preserving upload order' do
      post '/api/internal/templates',
           params: { external_id: 'multi-1', files: [pdf_upload('a.pdf'), pdf_upload('b.pdf')] },
           headers: { 'x-auth-token': api_key }

      expect(response).to have_http_status(:ok)

      template = account.templates.find_by(external_id: 'multi-1')
      expect(template.schema.size).to eq(2)
      expect(template.schema.pluck('name')).to eq(%w[a b])
    end

    it 'is idempotent by external_id — returns the existing template, no duplicate' do
      post '/api/internal/templates',
           params: { external_id: 'dup-1', files: [pdf_upload] },
           headers: { 'x-auth-token': api_key }
      first_id = response.parsed_body['id']

      expect do
        post '/api/internal/templates',
             params: { external_id: 'dup-1', files: [pdf_upload] },
             headers: { 'x-auth-token': api_key }
      end.not_to change(account.templates, :count)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(first_id)
    end

    it 'returns 401 without an auth token' do
      post '/api/internal/templates', params: { external_id: 'noauth', files: [pdf_upload] }

      expect(response).to have_http_status(:unauthorized)
      expect(account.templates.find_by(external_id: 'noauth')).to be_nil
    end

    it 'never returns or reuses another account template with the same external_id' do
      post '/api/internal/templates',
           params: { external_id: 'shared-ext', files: [pdf_upload] },
           headers: { 'x-auth-token': api_key }
      first_template = account.templates.find_by(external_id: 'shared-ext')

      other_account = create(:account)
      other_user = create(:user, account: other_account)

      post '/api/internal/templates',
           params: { external_id: 'shared-ext', files: [pdf_upload] },
           headers: { 'x-auth-token': other_user.access_token.token }

      expect(response).to have_http_status(:ok)

      other_template = other_account.templates.find_by(external_id: 'shared-ext')
      expect(other_template).to be_present
      expect(other_template.id).not_to eq(first_template.id)
      expect(response.parsed_body['id']).to eq(other_template.id)
    end
  end
end
