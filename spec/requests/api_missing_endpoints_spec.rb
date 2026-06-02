# frozen_string_literal: true

describe 'Additional API Endpoints' do
  let(:account) { create(:account, :with_testing_account) }
  let(:author) { create(:user, account:) }
  let(:token) { author.access_token.token }

  describe 'GET /api/user' do
    it 'returns the current user' do
      get '/api/user', headers: { 'x-auth-token': token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(author.id)
      expect(response.parsed_body['email']).to eq(author.email)
      expect(response.parsed_body['first_name']).to eq(author.first_name)
    end

    it 'returns unauthorized without a token' do
      get '/api/user'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/templates/:id/clone' do
    it 'clones a template' do
      template = create(:template, account:, author:, folder: create(:template_folder, account:))

      expect do
        post "/api/templates/#{template.id}/clone", headers: { 'x-auth-token': token },
                                                    params: { name: 'Cloned Template' }.to_json
      end.to change(Template, :count)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['name']).to eq('Cloned Template')
      expect(response.parsed_body['id']).not_to eq(template.id)
    end
  end

  describe 'GET /api/submissions/:id/documents' do
    it 'returns the documents for a submission' do
      template = create(:template, account:, author:)
      submission = create(:submission, template:, created_by_user: author)
      submitter = create(:submitter, submission:, uuid: template.submitters.first['uuid'],
                                     account:, completed_at: Time.current)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
        filename: 'sample-document.pdf',
        content_type: 'application/pdf'
      )
      ActiveStorage::Attachment.create!(blob:, name: :documents, record: submitter)

      get "/api/submissions/#{submission.id}/documents", headers: { 'x-auth-token': token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(submission.id)
      expect(response.parsed_body['documents']).to be_an(Array)
    end
  end

  describe 'GET /api/events/form/:type' do
    it 'returns form events for completed submitters' do
      template = create(:template, account:, author:, only_field_types: %w[text])
      submission = create(:submission, template:, created_by_user: author)
      create(:submitter, submission:, uuid: template.submitters.first['uuid'],
                         account:, completed_at: Time.current)

      get '/api/events/form/completed', headers: { 'x-auth-token': token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data']).to be_an(Array)
      expect(response.parsed_body['data'].first['event_type']).to eq('form.completed')
    end
  end

  describe 'GET /api/events/submission/:type' do
    it 'returns submission events for completed submissions' do
      template = create(:template, account:, author:, only_field_types: %w[text])
      submission = create(:submission, template:, created_by_user: author)
      create(:submitter, submission:, uuid: template.submitters.first['uuid'],
                         account:, completed_at: Time.current)

      get '/api/events/submission/completed', headers: { 'x-auth-token': token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data']).to be_an(Array)
      expect(response.parsed_body['data'].first['event_type']).to eq('submission.completed')
    end
  end

  describe 'POST /api/tools/merge' do
    it 'merges PDFs' do
      pdf_content = Base64.encode64(Rails.root.join('spec/fixtures/sample-document.pdf').read)

      post '/api/tools/merge', headers: { 'x-auth-token': token },
                               params: { files: [pdf_content, pdf_content] }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data']).to be_present
    end
  end
end
