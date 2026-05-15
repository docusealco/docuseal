# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadToPaperlessJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
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
      .to_return(status: 200, body: '"task-uuid-123"')
  end

  describe '#perform' do
    context 'when paperless-ngx is configured' do
      before do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
          filename: 'combined-result.pdf',
          content_type: 'application/pdf'
        )
        ActiveStorage::Attachment.create!(blob:, name: 'combined_document', record: submission)
      end

      it 'uploads documents to paperless-ngx' do
        described_class.new.perform('submission_id' => submission.id)

        expect(WebMock).to have_requested(:post, "#{paperless_url}/api/documents/post_document/")
          .at_least_once
      end
    end

    context 'when paperless-ngx is not configured' do
      before do
        allow(ENV).to receive(:[]).with('PAPERLESS_NGX_URL').and_return(nil)
        allow(ENV).to receive(:[]).with('PAPERLESS_NGX_TOKEN').and_return(nil)
      end

      it 'does nothing' do
        described_class.new.perform('submission_id' => submission.id)

        expect(WebMock).not_to have_requested(:post, /paperless/)
      end
    end

    context 'when submission does not exist' do
      it 'does nothing' do
        described_class.new.perform('submission_id' => -1)

        expect(WebMock).not_to have_requested(:post, /paperless/)
      end
    end

    context 'when upload fails with a retryable error' do
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

      it 'enqueues a retry with incremented attempt' do
        expect do
          described_class.new.perform('submission_id' => submission.id, 'attempt' => 0)
        end.to change(described_class.jobs, :size).by(1)

        args = described_class.jobs.last['args'].first
        expect(args['attempt']).to eq(1)
        expect(args['submission_id']).to eq(submission.id)
      end
    end

    context 'when max attempts is reached' do
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

      it 'does not enqueue another retry' do
        expect do
          described_class.new.perform('submission_id' => submission.id, 'attempt' => 11)
        end.not_to change(described_class.jobs, :size)
      end
    end
  end
end
