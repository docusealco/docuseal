# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Submissions::UploadToPaperless do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user, name: 'Employment Contract') }
  let(:submission) { create(:submission, :with_submitters, template:, created_by_user: user) }

  let(:paperless_url) { 'http://paperless:8000' }
  let(:paperless_token) { 'test-token-abc123' }

  before do
    submission.submitters.each_with_index do |submitter, i|
      submitter.update!(completed_at: i.hours.ago, name: "Signer #{i + 1}")
    end

    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('PAPERLESS_NGX_URL').and_return(paperless_url)
    allow(ENV).to receive(:[]).with('PAPERLESS_NGX_TOKEN').and_return(paperless_token)

    stub_request(:post, "#{paperless_url}/api/documents/post_document/")
      .to_return(status: 200, body: '"550e8400-e29b-41d4-a716-446655440000"')
  end

  describe '.call' do
    context 'when submission has a combined document' do
      before do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
          filename: 'combined-result.pdf',
          content_type: 'application/pdf'
        )
        ActiveStorage::Attachment.create!(blob:, name: 'combined_document', record: submission)
      end

      it 'uploads the combined document to paperless-ngx' do
        described_class.call(submission)

        expect(WebMock).to have_requested(:post, "#{paperless_url}/api/documents/post_document/")
          .with(headers: { 'Authorization' => "Token #{paperless_token}" })
          .once
      end

      it 'sends the correct title with template name and submitter names' do
        described_class.call(submission)

        expect(WebMock).to(have_requested(:post, "#{paperless_url}/api/documents/post_document/")
          .with { |req| req.body.include?('Employment Contract') && req.body.include?('Signer') })
      end

      it 'sends the created date' do
        described_class.call(submission)

        expect(WebMock).to(have_requested(:post, "#{paperless_url}/api/documents/post_document/")
          .with { |req| req.body.include?('created') })
      end

      it 'returns the task UUIDs from paperless-ngx' do
        result = described_class.call(submission)

        expect(result).to include('550e8400-e29b-41d4-a716-446655440000')
      end
    end

    context 'when submission has an audit trail' do
      before do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
          filename: 'audit-trail.pdf',
          content_type: 'application/pdf'
        )
        ActiveStorage::Attachment.create!(blob:, name: 'audit_trail', record: submission)
      end

      it 'uploads the audit trail to paperless-ngx' do
        described_class.call(submission)

        expect(WebMock).to(have_requested(:post, "#{paperless_url}/api/documents/post_document/")
          .with { |req| req.body.include?('Audit') }
          .once)
      end
    end

    context 'when submission has both combined document and audit trail' do
      before do
        combined_blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
          filename: 'combined-result.pdf',
          content_type: 'application/pdf'
        )
        ActiveStorage::Attachment.create!(blob: combined_blob, name: 'combined_document', record: submission)

        audit_blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
          filename: 'audit-trail.pdf',
          content_type: 'application/pdf'
        )
        ActiveStorage::Attachment.create!(blob: audit_blob, name: 'audit_trail', record: submission)
      end

      it 'uploads both documents to paperless-ngx' do
        described_class.call(submission)

        expect(WebMock).to have_requested(:post, "#{paperless_url}/api/documents/post_document/").twice
      end
    end

    context 'when submission has no combined document but has submitter documents' do
      before do
        submitter = submission.submitters.first
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
          filename: 'signed-result.pdf',
          content_type: 'application/pdf'
        )
        ActiveStorage::Attachment.create!(blob:, name: 'documents', record: submitter)
      end

      it 'uploads the submitter documents to paperless-ngx' do
        described_class.call(submission)

        expect(WebMock).to have_requested(:post, "#{paperless_url}/api/documents/post_document/")
          .at_least_once
      end
    end

    context 'when paperless-ngx env vars are not configured' do
      before do
        allow(ENV).to receive(:[]).with('PAPERLESS_NGX_URL').and_return(nil)
        allow(ENV).to receive(:[]).with('PAPERLESS_NGX_TOKEN').and_return(nil)
      end

      it 'does nothing and returns nil' do
        result = described_class.call(submission)

        expect(result).to be_nil
        expect(WebMock).not_to have_requested(:post, /paperless/)
      end
    end

    context 'when paperless-ngx returns an error' do
      before do
        stub_request(:post, "#{paperless_url}/api/documents/post_document/")
          .to_return(status: 500, body: 'Internal Server Error')

        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
          filename: 'combined-result.pdf',
          content_type: 'application/pdf'
        )
        ActiveStorage::Attachment.create!(blob:, name: 'combined_document', record: submission)
      end

      it 'raises an UploadError' do
        expect { described_class.call(submission) }.to raise_error(Submissions::UploadToPaperless::UploadError)
      end
    end

    context 'when paperless-ngx connection fails' do
      before do
        stub_request(:post, "#{paperless_url}/api/documents/post_document/")
          .to_timeout

        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
          filename: 'combined-result.pdf',
          content_type: 'application/pdf'
        )
        ActiveStorage::Attachment.create!(blob:, name: 'combined_document', record: submission)
      end

      it 'raises a connection error' do
        expect { described_class.call(submission) }.to raise_error(Faraday::ConnectionFailed)
      end
    end
  end

  describe '.configured?' do
    context 'when both env vars are set' do
      it 'returns true' do
        expect(described_class.configured?).to be true
      end
    end

    context 'when URL is missing' do
      before do
        allow(ENV).to receive(:[]).with('PAPERLESS_NGX_URL').and_return(nil)
      end

      it 'returns false' do
        expect(described_class.configured?).to be false
      end
    end

    context 'when token is missing' do
      before do
        allow(ENV).to receive(:[]).with('PAPERLESS_NGX_TOKEN').and_return(nil)
      end

      it 'returns false' do
        expect(described_class.configured?).to be false
      end
    end
  end
end
