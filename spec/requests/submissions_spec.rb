# frozen_string_literal: true

require 'rails_helper'

describe 'Submission API', type: :request do
  let!(:account) { create(:account) }
  let!(:author) { create(:user, account:) }
  let!(:folder) { create(:template_folder, account:) }
  let!(:templates) { create_list(:template, 2, account:, author:, folder:) }

  describe 'GET /api/submissions' do
    it 'returns a list of submissions' do
      submissions = [
        create(:submission, :with_submitters,
               template: templates[0],
               created_by_user: author),
        create(:submission, :with_submitters,
               template: templates[1],
               created_by_user: author)
      ].reverse

      get '/api/submissions', headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['pagination']).to eq(JSON.parse({
        count: submissions.size,
        next: submissions.last.id,
        prev: submissions.first.id
      }.to_json))
      expect(response.parsed_body['data']).to eq(JSON.parse(submissions.map { |t| index_submission_body(t) }.to_json))
    end
  end

  describe 'GET /api/submissions/:id' do
    it 'returns a submission' do
      submission = create(:submission, :with_submitters, :with_events, template: templates[0], created_by_user: author)

      get "/api/submissions/#{submission.id}", headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(JSON.parse(show_submission_body(submission).to_json))
    end
  end

  describe 'POST /api/submissions' do
    it 'creates a submission' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [{ role: 'First Role', email: 'john.doe@example.com' }]
      }.to_json

      expect(response).to have_http_status(:ok)

      submission = Submission.last

      expect(response.parsed_body).to eq(JSON.parse(create_submission_body(submission).to_json))
    end

    it 'returns an error if the template fields are missing' do
      templates[0].update(fields: [])

      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [{ role: 'First Role', email: 'john.doe@example.com' }]
      }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq({ 'error' => 'Template does not contain fields' })
    end

    it 'returns an error if submitter roles are not unique' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [
          { role: 'First Role', email: 'john.doe@example.com' },
          { role: 'First Role', email: 'jane.doe@example.com' }
        ]
      }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq({ 'error' => 'role must be unique in `submitters`.' })
    end
  end

  describe 'POST /api/submissions/emails' do
    it 'creates a submission using email' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        emails: 'john.doe@example.com'
      }.to_json

      expect(response).to have_http_status(:ok)

      submission = Submission.last

      expect(response.parsed_body).to eq(JSON.parse(create_submission_body(submission).to_json))
    end
  end

  describe 'DELETE /api/submissions/:id' do
    it 'archives a submission' do
      submission = create(:submission, :with_submitters, template: templates[0], created_by_user: author)

      delete "/api/submissions/#{submission.id}", headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:ok)

      submission.reload

      expect(submission.archived_at).not_to be_nil
      expect(response.parsed_body).to eq(JSON.parse({
        id: submission.id,
        archived_at: submission.archived_at
      }.to_json))
    end
  end

  private

  def index_submission_body(submission)
    submitters = submission.submitters.map do |submitter|
      {
        id: submitter.id,
        submission_id: submission.id,
        uuid: submitter.uuid,
        email: submitter.email,
        slug: submitter.slug,
        sent_at: submitter.sent_at,
        opened_at: submitter.opened_at,
        completed_at: submitter.completed_at,
        declined_at: nil,
        created_at: submitter.created_at,
        updated_at: submitter.updated_at,
        name: submitter.name,
        phone: submitter.phone,
        status: submitter.status,
        role: submitter.template.submitters.find { |s| s['uuid'] == submitter.uuid }['name'],
        external_id: nil,
        application_key: nil, # Backward compatibility
        metadata: {},
        preferences: {}
      }
    end

    {
      id: submission.id,
      source: 'link',
      submitters_order: 'random',
      slug: submission.slug,
      audit_log_url: nil,
      combined_document_url: nil,
      expire_at: nil,
      completed_at: nil,
      created_at: submission.created_at,
      updated_at: submission.updated_at,
      archived_at: nil,
      status: 'pending',
      submitters:,
      template: {
        id: submission.template.id,
        name: submission.template.name,
        external_id: nil,
        folder_name: folder.name,
        created_at: submission.template.created_at,
        updated_at: submission.template.updated_at
      },
      created_by_user: {
        id: author.id,
        first_name: author.first_name,
        last_name: author.last_name,
        email: author.email
      }
    }
  end

  def show_submission_body(submission)
    submitters = submission.submitters.map do |submitter|
      {
        id: submitter.id,
        submission_id: submission.id,
        uuid: submitter.uuid,
        email: submitter.email,
        slug: submitter.slug,
        sent_at: submitter.sent_at,
        opened_at: submitter.opened_at,
        completed_at: submitter.completed_at,
        declined_at: nil,
        created_at: submitter.created_at,
        updated_at: submitter.updated_at,
        name: submitter.name,
        phone: submitter.phone,
        status: submitter.status,
        external_id: nil,
        application_key: nil, # Backward compatibility
        metadata: {},
        preferences: {},
        role: submitter.template.submitters.find { |s| s['uuid'] == submitter.uuid }['name'],
        documents: [],
        values: []
      }
    end

    {
      id: submission.id,
      source: 'link',
      status: 'pending',
      submitters_order: 'random',
      slug: submission.slug,
      audit_log_url: nil,
      combined_document_url: nil,
      expire_at: nil,
      completed_at: nil,
      created_at: submission.created_at,
      updated_at: submission.updated_at,
      archived_at: nil,
      submitters:,
      template: {
        id: submission.template.id,
        name: submission.template.name,
        external_id: nil,
        folder_name: folder.name,
        created_at: submission.template.created_at,
        updated_at: submission.template.updated_at
      },
      created_by_user: {
        id: author.id,
        first_name: author.first_name,
        last_name: author.last_name,
        email: author.email
      },
      documents: [],
      submission_events: submission.submission_events.map do |event|
        {
          id: event.id,
          submitter_id: event.submitter_id,
          event_type: event.event_type,
          event_timestamp: event.event_timestamp,
          data: event.data.slice(:reason)
        }
      end
    }
  end

  def create_submission_body(submission)
    submission.submitters.map do |submitter|
      {
        id: submitter.id,
        submission_id: submission.id,
        uuid: submitter.uuid,
        email: submitter.email,
        slug: submitter.slug,
        sent_at: submitter.sent_at,
        opened_at: submitter.opened_at,
        completed_at: submitter.completed_at,
        declined_at: nil,
        created_at: submitter.created_at,
        updated_at: submitter.updated_at,
        name: submitter.name,
        phone: submitter.phone,
        status: submitter.status,
        external_id: nil,
        application_key: nil, # Backward compatibility
        metadata: {},
        preferences: { send_email: true, send_sms: false },
        role: submitter.template.submitters.find { |s| s['uuid'] == submitter.uuid }['name'],
        embed_src: "#{Docuseal::DEFAULT_APP_URL}/s/#{submitter.slug}",
        values: []
      }
    end
  end
end
