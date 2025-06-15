# frozen_string_literal: true

describe 'Submission API' do
  let(:account) { create(:account, :with_testing_account) }
  let(:testing_account) { account.testing_accounts.first }
  let(:author) { create(:user, account:) }
  let(:testing_author) { create(:user, account: testing_account) }
  let(:folder) { create(:template_folder, account:) }
  let(:testing_folder) { create(:template_folder, account: testing_account) }
  let(:templates) { create_list(:template, 2, account:, author:, folder:) }
  let(:multiple_submitters_template) { create(:template, submitter_count: 3, account:, author:, folder:) }
  let(:testing_templates) do
    create_list(:template, 2, account: testing_account, author: testing_author, folder: testing_folder)
  end

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

    it 'returns an authorization error if test account API token is used with a production submission' do
      submission = create(:submission, :with_submitters, :with_events, template: templates[0], created_by_user: author)

      get "/api/submissions/#{submission.id}", headers: { 'x-auth-token': testing_author.access_token.token }

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq(
        JSON.parse({ error: "Submission #{submission.id} not found using testing API key; " \
                            'Use production API key to access production submissions.' }.to_json)
      )
    end

    it 'returns an authorization error if production account API token is used with a test submission' do
      submission = create(:submission, :with_submitters, :with_events, template: testing_templates[0],
                                                                       created_by_user: testing_author)

      get "/api/submissions/#{submission.id}", headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq(
        JSON.parse({ error: "Submission #{submission.id} not found using production API key; " \
                            'Use testing API key to access testing submissions.' }.to_json)
      )
    end
  end

  describe 'POST /api/submissions' do
    it 'creates a submission' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [{ role: 'First Party', email: 'john.doe@example.com' }]
      }.to_json

      expect(response).to have_http_status(:ok)

      submission = Submission.last

      expect(response.parsed_body).to eq(JSON.parse(create_submission_body(submission).to_json))
    end

    it 'creates a submission when the message is empty' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [{ role: 'First Party', email: 'john.doe@example.com' }],
        message: {}
      }.to_json

      expect(response).to have_http_status(:ok)

      submission = Submission.last

      expect(response.parsed_body).to eq(JSON.parse(create_submission_body(submission).to_json))
    end

    it 'creates a submission when the submitter is marked as completed' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        submitters: [{ role: 'First Party', email: 'john.doe@example.com', completed: true }]
      }.to_json

      expect(response).to have_http_status(:ok)

      submission = Submission.last
      submitter = submission.submitters.first

      expect(submitter.status).to eq('completed')
      expect(submitter.completed_at).not_to be_nil
    end

    it 'creates a submission when some submitter roles are not provided' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: multiple_submitters_template.id,
        send_email: true,
        submitters: [
          { role: 'First Party', email: 'john.doe@example.com' },
          { email: 'jane.doe@example.com' },
          { email: 'mike.doe@example.com' }
        ]
      }.to_json

      expect(response).to have_http_status(:ok)

      submission = Submission.last

      expect(response.parsed_body).to eq(JSON.parse(create_submission_body(submission).to_json))
      expect(response.parsed_body).to eq(JSON.parse(create_submission_body(submission).to_json))
      expect(response.parsed_body[0]['role']).to eq('First Party')
      expect(response.parsed_body[0]['email']).to eq('john.doe@example.com')
      expect(response.parsed_body[1]['role']).to eq('Second Party')
      expect(response.parsed_body[1]['email']).to eq('jane.doe@example.com')
      expect(response.parsed_body[2]['role']).to eq('Third Party')
      expect(response.parsed_body[2]['email']).to eq('mike.doe@example.com')
    end

    it 'returns an error if the submitter email is invalid' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [
          { role: 'First Party', email: 'john@example' }
        ]
      }.to_json

      expect(response).to have_http_status(:unprocessable_entity)

      expect(response.parsed_body).to eq({ 'error' => 'email is invalid in `submitters[0]`.' })
    end

    it 'returns an error if the template fields are missing' do
      templates[0].update(fields: [])

      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [{ role: 'First Party', email: 'john.doe@example.com' }]
      }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq({ 'error' => 'Template does not contain fields' })
    end

    it 'returns an error if submitter roles are not unique' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: multiple_submitters_template.id,
        send_email: true,
        submitters: [
          { role: 'First Party', email: 'john.doe@example.com' },
          { role: 'First Party', email: 'jane.doe@example.com' }
        ]
      }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq({ 'error' => 'role must be unique in `submitters`.' })
    end

    it 'returns an error if number of submitters more than in the template' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [
          { email: 'jane.doe@example.com' },
          { role: 'First Party', email: 'john.doe@example.com' }
        ]
      }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq({ 'error' => 'Defined more signing parties than in template' })
    end

    it 'returns an error if the message has no body value' do
      post '/api/submissions', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        send_email: true,
        submitters: [
          { role: 'First Party', email: 'john.doe@example.com' }
        ],
        message: {
          subject: 'Custom Email Subject'
        }
      }.to_json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq({ 'error' => 'body is required in `message`.' })
    end
  end

  describe 'POST /api/submissions/emails' do
    it 'creates a submission using email' do
      post '/api/submissions/emails', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        emails: 'john.doe@example.com,jane.doe@example.com'
      }.to_json

      expect(response).to have_http_status(:ok)

      submissions = Submission.last(2)
      submissions_body = submissions.reduce([]) { |acc, submission| acc + create_submission_body(submission) }

      expect(response.parsed_body).to eq(JSON.parse(submissions_body.to_json))
    end

    it 'returns an error if emails are invalid' do
      post '/api/submissions/emails', headers: { 'x-auth-token': author.access_token.token }, params: {
        template_id: templates[0].id,
        emails: 'amy.baker@example.com, george.morris@example.com@gmail.com'
      }.to_json

      expect(response).to have_http_status(:unprocessable_entity)

      expect(response.parsed_body).to eq({ 'error' => 'emails are invalid' })
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
      name: submission.name,
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
      name: submission.name,
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
        values: Submitters::SerializeForWebhook.build_values_array(submitter)
      }
    end
  end
end
