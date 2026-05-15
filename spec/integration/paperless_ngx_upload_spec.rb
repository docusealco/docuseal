# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/DescribeClass, RSpec/InstanceVariable, RSpec/ExpectInHook

# Run with: docker compose -f docker-compose.e2e.yml up
# This spec requires a running paperless-ngx instance.
# It acquires a token from paperless-ngx, uploads a document, and verifies it was received.
RSpec.describe 'Paperless-ngx document upload', type: :integration do
  let(:paperless_url) { ENV.fetch('PAPERLESS_NGX_URL', 'http://paperless-ngx:8000') }
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user, name: 'Integration Test Contract') }
  let(:submission) { create(:submission, :with_submitters, template:, created_by_user: user) }

  # Generate a unique PDF per test by appending a random trailer comment.
  # This ensures paperless-ngx does not deduplicate uploads across tests.
  def unique_pdf_io
    base_pdf = Rails.root.join('spec/fixtures/sample-document.pdf').binread
    unique_pdf = base_pdf + "\n% #{SecureRandom.uuid}\n"
    StringIO.new(unique_pdf)
  end

  before do
    # Skip if paperless-ngx is not reachable
    WebMock.allow_net_connect!

    begin
      health = Faraday.get("#{paperless_url}/api/") { |req| req.options.open_timeout = 5 }
      skip "Paperless-ngx not available (HTTP #{health.status})" unless health.status < 400
    rescue Faraday::Error
      skip 'Paperless-ngx not available (connection failed)'
    end

    # Acquire a token from paperless-ngx
    token_response = Faraday.post("#{paperless_url}/api/token/") do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { username: 'admin', password: 'admin' }.to_json
    end

    expect(token_response.status).to eq(200), "Failed to get paperless-ngx token: #{token_response.body}"
    @paperless_token = JSON.parse(token_response.body)['token']

    # Configure ENV for the upload module
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('PAPERLESS_NGX_URL').and_return(paperless_url)
    allow(ENV).to receive(:[]).with('PAPERLESS_NGX_TOKEN').and_return(@paperless_token)

    # Mark all submitters as completed
    submission.submitters.each_with_index do |submitter, i|
      submitter.update!(completed_at: i.hours.ago, name: "Test Signer #{i + 1}")
    end

    # Attach a combined document with unique content per test
    blob = ActiveStorage::Blob.create_and_upload!(
      io: unique_pdf_io,
      filename: "integration-test-#{SecureRandom.hex(4)}.pdf",
      content_type: 'application/pdf'
    )
    ActiveStorage::Attachment.create!(blob:, name: 'combined_document', record: submission)
  end

  after do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  it 'uploads a signed document to paperless-ngx and receives a task UUID' do
    result = Submissions::UploadToPaperless.call(submission)

    expect(result).to be_present
    expect(result.first).to match(/\A[0-9a-f-]+\z/)
  end

  it 'uploads via the background job without error' do
    expect do
      UploadToPaperlessJob.new.perform('submission_id' => submission.id)
    end.not_to raise_error
  end

  it 'document is consumable by paperless-ngx' do
    result = Submissions::UploadToPaperless.call(submission)
    task_id = result.first

    # Poll the tasks API to verify consumption started
    response = Faraday.get("#{paperless_url}/api/tasks/?task_id=#{task_id}") do |req|
      req.headers['Authorization'] = "Token #{@paperless_token}"
    end

    expect(response.status).to eq(200)
    tasks = JSON.parse(response.body)
    expect(tasks).to be_present
  end
end

# rubocop:enable RSpec/DescribeClass, RSpec/InstanceVariable, RSpec/ExpectInHook
