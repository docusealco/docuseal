# frozen_string_literal: true

describe 'Embed forms' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account: account) }
  let(:template) { create(:template, account: account, author: author, shared_link: true) }

  describe 'POST /embed/forms' do
    it 'returns a shared template payload before the signer starts' do
      post '/embed/forms', params: { slug: template.slug }.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('template', 'id')).to eq(template.id)
      expect(response.parsed_body['submitter']).to be_nil
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'creates an embedded submitter and returns signing data' do
      post '/embed/forms',
           params: { slug: template.slug, email: 'signer@example.com', name: 'Jane Signer' }.to_json,
           headers: { 'CONTENT_TYPE' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('submitter', 'email')).to eq('signer@example.com')
      expect(response.parsed_body.dig('submission', 'source')).to eq('embed')
      expect(response.parsed_body.dig('submission', 'template_fields')).to be_present
      expect(response.parsed_body['documents']).to be_present
    end

    it 'loads an existing submitter by slug' do
      submitter = create(:submission, :with_submitters, template: template).submitters.first

      post '/embed/forms', params: { slug: submitter.slug }.to_json, headers: { 'CONTENT_TYPE' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('submitter', 'slug')).to eq(submitter.slug)
    end
  end

  describe 'OPTIONS /embed/forms' do
    it 'returns CORS preflight headers' do
      process :options, '/embed/forms'

      expect(response).to have_http_status(:ok)
      expect(response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(response.headers['Access-Control-Allow-Methods']).to include('POST')
      expect(response.headers['Access-Control-Allow-Headers']).to eq('*')
    end
  end
end
