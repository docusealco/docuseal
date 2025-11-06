# frozen_string_literal: true

require 'rails_helper'

describe 'Signed Document URLs API' do
  let(:account) { create(:account, :with_testing_account) }
  let(:testing_account) { account.testing_accounts.first }
  let(:author) { create(:user, account:) }
  let(:testing_author) { create(:user, account: testing_account) }
  let(:template) { create(:template, account:, author:) }
  let(:testing_template) { create(:template, account: testing_account, author: testing_author) }

  before do
    ActiveStorage::Current.url_options = { host: 'test.example.com' }
  end

  describe 'GET /api/submissions/:submission_id/signed_document_url' do
    context 'with a completed submission' do
      let(:submission) { create(:submission, :with_submitters, template:, created_by_user: author) }
      let(:completed_submitter) { submission.submitters.first }

      before do
        # Mark submitter as completed
        completed_submitter.update!(completed_at: Time.current)

        # Create a document attachment for the submitter
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test pdf content'),
          filename: 'completed-document.pdf',
          content_type: 'application/pdf'
        )
        completed_submitter.documents.attach(blob)
      end

      it 'returns signed URLs for completed documents' do
        allow(Submissions::EnsureResultGenerated).to receive(:call).and_return(completed_submitter.documents)

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['submission_id']).to eq(submission.id)
        expect(response.parsed_body['submitter_id']).to eq(completed_submitter.id)
        expect(response.parsed_body['documents']).to be_an(Array)
        expect(response.parsed_body['documents'].size).to eq(1)

        document = response.parsed_body['documents'].first
        expect(document['name']).to eq('completed-document.pdf')
        expect(document['url']).to be_present
        expect(document['size_bytes']).to be_a(Integer)
        expect(document['content_type']).to eq('application/pdf')
      end

      it 'calls EnsureResultGenerated to generate documents if needed' do
        expect(Submissions::EnsureResultGenerated).to receive(:call).with(completed_submitter)

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:ok)
      end

      it 'uses standard ActiveStorage URLs for disk storage' do
        allow(Submissions::EnsureResultGenerated).to receive(:call).and_return(completed_submitter.documents)

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:ok)

        document = response.parsed_body['documents'].first
        # For disk storage in test, should use proxy URL pattern
        expect(document['url']).to include('/file/')
      end

      it 'includes document metadata' do
        allow(Submissions::EnsureResultGenerated).to receive(:call).and_return(completed_submitter.documents)

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:ok)

        document = response.parsed_body['documents'].first
        expect(document).to have_key('name')
        expect(document).to have_key('url')
        expect(document).to have_key('size_bytes')
        expect(document).to have_key('content_type')
      end
    end

    context 'with secured storage (CloudFront)' do
      let(:submission) { create(:submission, :with_submitters, template:, created_by_user: author) }
      let(:completed_submitter) { submission.submitters.first }

      before do
        completed_submitter.update!(completed_at: Time.current)

        # Create a regular document (test storage)
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test pdf content'),
          filename: 'secured-document.pdf',
          content_type: 'application/pdf'
        )
        completed_submitter.documents.attach(blob)

        # Mock CloudFront configuration
        allow(ENV).to receive(:fetch).with('CF_URL', nil).and_return('https://d123.cloudfront.net')
        allow(ENV).to receive(:fetch).with('CF_KEY_PAIR_ID', nil).and_return('TEST_KEY')
        allow(ENV).to receive(:fetch).with('SECURE_ATTACHMENT_PRIVATE_KEY', nil).and_return('test-key')

        signer = instance_double(Aws::CloudFront::UrlSigner)
        allow(Aws::CloudFront::UrlSigner).to receive(:new).and_return(signer)
        allow(signer).to receive(:signed_url).and_return('https://d123.cloudfront.net/signed-url')
      end

      after do
        DocumentSecurityService.instance_variable_set(:@cloudfront_signer, nil)
      end

      it 'uses DocumentSecurityService for secured storage' do
        allow(Submissions::EnsureResultGenerated).to receive(:call).and_return(completed_submitter.documents)

        # Stub Submitters.select_attachments_for_download to return the documents
        allow(Submitters).to receive(:select_attachments_for_download).and_return(completed_submitter.documents)

        # Mock the attachment's blob to appear as if it's using aws_s3_secured service
        completed_submitter.documents.each do |attachment|
          allow(attachment.blob).to receive(:service_name).and_return('aws_s3_secured')
        end

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:ok)

        document = response.parsed_body['documents'].first
        expect(document['url']).to include('cloudfront.net')
      end
    end

    context 'with an incomplete submission' do
      let(:submission) { create(:submission, :with_submitters, template:, created_by_user: author) }

      it 'returns an error when submission is not completed' do
        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq({ 'error' => 'Submission not completed' })
      end

      it 'does not call EnsureResultGenerated for incomplete submissions' do
        expect(Submissions::EnsureResultGenerated).not_to receive(:call)

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with multiple completed submitters' do
      let(:template) { create(:template, submitter_count: 2, account:, author:) }
      let(:submission) { create(:submission, :with_submitters, template:, created_by_user: author) }

      before do
        # Complete first submitter
        submission.submitters.first.update!(completed_at: 1.hour.ago)
        blob1 = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('first document'),
          filename: 'first-document.pdf',
          content_type: 'application/pdf'
        )
        submission.submitters.first.documents.attach(blob1)

        # Complete second submitter (most recent)
        submission.submitters.last.update!(completed_at: Time.current)
        blob2 = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('second document'),
          filename: 'second-document.pdf',
          content_type: 'application/pdf'
        )
        submission.submitters.last.documents.attach(blob2)
      end

      it 'returns documents from the last completed submitter' do
        allow(Submissions::EnsureResultGenerated).to receive(:call).and_return(submission.submitters.last.documents)

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['submitter_id']).to eq(submission.submitters.last.id)
        expect(response.parsed_body['documents'].first['name']).to eq('second-document.pdf')
      end
    end

    context 'with multiple documents' do
      let(:submission) { create(:submission, :with_submitters, template:, created_by_user: author) }
      let(:completed_submitter) { submission.submitters.first }

      before do
        completed_submitter.update!(completed_at: Time.current)

        # Create multiple document attachments
        blob1 = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('first pdf'),
          filename: 'document-1.pdf',
          content_type: 'application/pdf'
        )
        blob2 = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('second pdf'),
          filename: 'document-2.pdf',
          content_type: 'application/pdf'
        )
        completed_submitter.documents.attach([blob1, blob2])
      end

      it 'returns all documents' do
        allow(Submissions::EnsureResultGenerated).to receive(:call).and_return(completed_submitter.documents)

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['documents'].size).to eq(2)
        expect(response.parsed_body['documents'].map { |d| d['name'] }).to contain_exactly(
          'document-1.pdf',
          'document-2.pdf'
        )
      end
    end

    context 'with authorization' do
      let(:submission) { create(:submission, :with_submitters, template:, created_by_user: author) }

      before do
        submission.submitters.first.update!(completed_at: Time.current)
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
        submission.submitters.first.documents.attach(blob)
      end

      it 'returns error when using testing API token for production submission' do
        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': testing_author.access_token.token }

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body['error']).to include('testing API key')
      end

      it 'returns error when using production API token for testing submission' do
        testing_submission = create(:submission, :with_submitters, template: testing_template,
                                                                    created_by_user: testing_author)
        testing_submission.submitters.first.update!(completed_at: Time.current)
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
        testing_submission.submitters.first.documents.attach(blob)

        get "/api/submissions/#{testing_submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body['error']).to include('production API key')
      end

      it 'returns error when no auth token is provided' do
        get "/api/submissions/#{submission.id}/signed_document_url"

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq({ 'error' => 'Not authenticated' })
      end

      it 'raises RecordNotFound when submission does not exist' do
        expect do
          get '/api/submissions/99999/signed_document_url',
              headers: { 'x-auth-token': author.access_token.token }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'allows access with valid token for same account' do
        allow(Submissions::EnsureResultGenerated).to receive(:call).and_return(submission.submitters.first.documents)

        get "/api/submissions/#{submission.id}/signed_document_url",
            headers: { 'x-auth-token': author.access_token.token }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when EnsureResultGenerated fails' do
      let(:submission) { create(:submission, :with_submitters, template:, created_by_user: author) }

      before do
        submission.submitters.first.update!(completed_at: Time.current)
      end

      it 'propagates the error' do
        allow(Submissions::EnsureResultGenerated).to receive(:call).and_raise(StandardError, 'Generation failed')

        expect do
          get "/api/submissions/#{submission.id}/signed_document_url",
              headers: { 'x-auth-token': author.access_token.token }
        end.to raise_error(StandardError, 'Generation failed')
      end
    end
  end
end
