# frozen_string_literal: true

describe 'Submitter API' do
  let(:account) { create(:account, :with_testing_account) }
  let(:testing_account) { account.testing_accounts.first }
  let(:author) { create(:user, account:) }
  let(:testing_author) { create(:user, account: testing_account) }
  let(:folder) { create(:template_folder, account:) }
  let(:testing_folder) { create(:template_folder, account: testing_account) }
  let(:templates) { create_list(:template, 2, account:, author:, folder:) }
  let(:testing_templates) do
    create_list(:template, 2, account: testing_account, author: testing_author, folder: testing_folder)
  end

  describe 'GET /api/submitters' do
    it 'returns a list of submitters' do
      submitters = [
        create(:submission, :with_submitters, :with_events,
               template: templates[0],
               created_by_user: author),
        create(:submission, :with_submitters,
               template: templates[1],
               created_by_user: author)
      ].map(&:submitters).flatten.reverse

      get '/api/submitters', headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['pagination']).to eq(JSON.parse({
        count: submitters.size,
        next: submitters.last.id,
        prev: submitters.first.id
      }.to_json))
      expect(response.parsed_body['data']).to eq(JSON.parse(submitters.map { |t| submitter_body(t) }.to_json))
    end
  end

  describe 'GET /api/submitters/:id' do
    it 'returns a submitter' do
      submitter = create(:submission, :with_submitters, :with_events,
                         template: templates[0],
                         created_by_user: author).submitters.first

      get "/api/submitters/#{submitter.id}", headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(JSON.parse(submitter_body(submitter).to_json))
    end

    it 'returns an authorization error if test account API token is used with a production submitter' do
      submitter = create(:submission, :with_submitters, :with_events,
                         template: templates[0],
                         created_by_user: author).submitters.first

      get "/api/submitters/#{submitter.id}", headers: { 'x-auth-token': testing_author.access_token.token }

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq(
        JSON.parse({ error: "Submitter #{submitter.id} not found using " \
                            'testing API key; Use production API key to access production submitters.' }.to_json)
      )
    end

    it 'returns an authorization error if production account API token is used with a test submitter' do
      submitter = create(:submission, :with_submitters, :with_events,
                         template: testing_templates[0],
                         created_by_user: testing_author).submitters.first

      get "/api/submitters/#{submitter.id}", headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq(
        JSON.parse({ error: "Submitter #{submitter.id} not found using production API key; " \
                            'Use testing API key to access testing submitters.' }.to_json)
      )
    end
  end

  describe 'PUT /api/submitters' do
    it 'update a submitter' do
      submitter = create(:submission, :with_submitters, :with_events,
                         template: templates[0],
                         created_by_user: author).submitters.first

      put "/api/submitters/#{submitter.id}", headers: { 'x-auth-token': author.access_token.token }, params: {
        email: 'john.doe+updated@example.com'
      }.to_json

      expect(response).to have_http_status(:ok)

      submitter.reload

      expect(submitter.email).to eq('john.doe+updated@example.com')
      expect(response.parsed_body).to eq(JSON.parse(update_submitter_body(submitter).to_json))
    end

    it 'marks a submitter as completed' do
      submitter = create(:submission, :with_submitters, :with_events,
                         template: templates[0],
                         created_by_user: author).submitters.first

      put "/api/submitters/#{submitter.id}", headers: { 'x-auth-token': author.access_token.token }, params: {
        completed: true
      }.to_json

      expect(response).to have_http_status(:ok)

      submitter.reload

      expect(submitter.status).to eq('completed')
      expect(submitter.completed_at).not_to be_nil
    end
  end

  private

  def submitter_body(submitter)
    {
      id: submitter.id,
      submission_id: submitter.submission_id,
      uuid: submitter.uuid,
      email: submitter.email,
      status: submitter.status,
      slug: submitter.slug,
      sent_at: submitter.sent_at,
      opened_at: submitter.opened_at,
      completed_at: submitter.completed_at,
      declined_at: submitter.declined_at,
      created_at: submitter.created_at,
      updated_at: submitter.updated_at,
      name: submitter.name,
      phone: submitter.phone,
      external_id: nil,
      application_key: nil, # Backward compatibility
      template: {
        id: submitter.template.id,
        name: submitter.template.name,
        created_at: submitter.template.created_at,
        updated_at: submitter.template.updated_at
      },
      metadata: {},
      preferences: {},
      submission_events: submitter.submission_events.map do |event|
        {
          id: event.id,
          submitter_id: event.submitter_id,
          event_type: event.event_type,
          event_timestamp: event.event_timestamp,
          data: event.data.slice(:reason)
        }
      end,
      values: Submitters::SerializeForWebhook.build_values_array(submitter),
      documents: Submitters::SerializeForWebhook.build_documents_array(submitter),
      role: submitter.template.submitters.find { |s| s['uuid'] == submitter.uuid }['name']
    }
  end

  def update_submitter_body(submitter)
    submitter_body(submitter).except(:template, :submission_events)
                             .merge(embed_src: "#{Docuseal::DEFAULT_APP_URL}/s/#{submitter.slug}")
  end
end
