# frozen_string_literal: true

describe 'Tools API' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }
  let(:file_path) { Rails.root.join('spec/fixtures/sample-document.pdf') }

  before do
    create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                              value: GenerateCertificate.call.transform_values(&:to_pem))
  end

  describe 'POST /api/tools/verify' do
    it 'returns a verification result' do
      template = create(:template, account:, author:)
      submission = create(:submission, :with_submitters, :with_events, template:, created_by_user: author)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file_path.open,
        filename: 'sample-document.pdf',
        content_type: 'application/pdf'
      )
      create(:completed_document, submitter: submission.submitters.first,
                                  sha256: Base64.urlsafe_encode64(Digest::SHA256.digest(blob.download)))

      ActiveStorage::Attachment.create!(
        blob:,
        name: :documents,
        record: submission.submitters.first
      )

      post '/api/tools/verify', headers: { 'x-auth-token': author.access_token.token }, params: {
        file: Base64.encode64(File.read(file_path))
      }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['checksum_status']).to eq('verified')
    end
  end
end
