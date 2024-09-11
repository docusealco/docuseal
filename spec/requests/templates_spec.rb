# frozen_string_literal: true

require 'rails_helper'

describe 'Templates API', type: :request do
  let!(:account) { create(:account) }
  let!(:author) { create(:user, account:) }
  let!(:folder) { create(:template_folder, account:) }
  let!(:template_preferences) { { 'request_email_subject' => 'Subject text', 'request_email_body' => 'Body Text' } }

  describe 'GET /api/templates' do
    it 'returns a list of templates' do
      templates = [
        create(:template, account:,
                          author:,
                          folder:,
                          external_id: SecureRandom.base58(10),
                          preferences: template_preferences),
        create(:template, account:,
                          author:,
                          folder:,
                          external_id: SecureRandom.base58(10),
                          preferences: template_preferences)
      ].reverse

      get '/api/templates', headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['pagination']).to eq(JSON.parse({
        count: templates.size,
        next: templates.last.id,
        prev: templates.first.id
      }.to_json))
      expect(response.parsed_body['data']).to eq(JSON.parse(templates.map { |t| template_body(t) }.to_json))
    end
  end

  describe 'GET /api/templates/:id' do
    it 'returns a template' do
      template = create(:template, account:,
                                   author:,
                                   folder:,
                                   external_id: SecureRandom.base58(10),
                                   preferences: template_preferences)

      get "/api/templates/#{template.id}", headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(JSON.parse(template_body(template).to_json))
    end
  end

  describe 'PUT /api/templates' do
    it 'update a template' do
      template = create(:template, account:,
                                   author:,
                                   folder:,
                                   external_id: SecureRandom.base58(10),
                                   preferences: template_preferences)

      put "/api/templates/#{template.id}", headers: { 'x-auth-token': author.access_token.token }, params: {
        name: 'Updated Template Name',
        external_id: '123456'
      }.to_json

      expect(response).to have_http_status(:ok)

      template.reload

      expect(template.name).to eq('Updated Template Name')
      expect(template.external_id).to eq('123456')
      expect(response.parsed_body).to eq(JSON.parse({
        id: template.id,
        updated_at: template.updated_at
      }.to_json))
    end
  end

  describe 'DELETE /api/templates/:id' do
    it 'archives a template' do
      template = create(:template, account:,
                                   author:,
                                   folder:,
                                   external_id: SecureRandom.base58(10),
                                   preferences: template_preferences)

      delete "/api/templates/#{template.id}", headers: { 'x-auth-token': author.access_token.token }

      expect(response).to have_http_status(:ok)

      template.reload

      expect(template.archived_at).not_to be_nil
      expect(response.parsed_body).to eq(JSON.parse({
        id: template.id,
        archived_at: template.archived_at
      }.to_json))
    end
  end

  describe 'POST /api/templates/:id/clone' do
    it 'clones a template' do
      template = create(:template, account:,
                                   author:,
                                   folder:,
                                   external_id: SecureRandom.base58(10),
                                   preferences: template_preferences)

      expect do
        post "/api/templates/#{template.id}/clone", headers: { 'x-auth-token': author.access_token.token }, params: {
          name: 'Cloned Template Name',
          external_id: '123456'
        }.to_json
      end.to change(Template, :count)

      expect(response).to have_http_status(:ok)

      cloned_template = Template.last

      expect(cloned_template.name).to eq('Cloned Template Name')
      expect(cloned_template.external_id).to eq('123456')
      expect(response.parsed_body).to eq(JSON.parse(clone_template_body(cloned_template).to_json))
    end
  end

  private

  def template_body(template)
    template_attachment_uuid = template.schema.first['attachment_uuid']
    attachment = template.schema_documents.preload(:blob).find { |e| e.uuid == template_attachment_uuid }
    first_page_blob =
      ActiveStorage::Attachment.joins(:blob)
                               .where(blob: { filename: '0.png' })
                               .where(record_id: template.schema_documents.map(&:id),
                                      record_type: 'ActiveStorage::Attachment',
                                      name: :preview_images)
                               .preload(:blob)
                               .first
                               .blob

    {
      id: template.id,
      slug: template.slug,
      name: template.name,
      fields: [
        {
          'uuid' => '21637fc9-0655-45df-8952-04ec64949e85',
          'submitter_uuid' => '513848eb-1096-4abc-a743-68596b5aaa4c',
          'name' => 'First Name',
          'type' => 'text',
          'required' => true,
          'areas' => [
            {
              'x' => 0.09027777777777778,
              'y' => 0.1197252208047105,
              'w' => 0.3069444444444444,
              'h' => 0.03336604514229637,
              'attachment_uuid' => template_attachment_uuid,
              'page' => 0
            }
          ]
        },
        {
          'uuid' => '1f97f8e3-dc82-4586-aeea-6ebed6204e46',
          'submitter_uuid' => '513848eb-1096-4abc-a743-68596b5aaa4c',
          'name' => '',
          'type' => 'signature',
          'required' => true,
          'areas' => []
        }
      ],
      submitters: [
        {
          name: 'First Party',
          uuid: template.submitters.first['uuid']
        }
      ],
      author: {
        id: author.id,
        first_name: author.first_name,
        last_name: author.last_name,
        email: author.email
      },
      documents: [
        {
          id: template.documents.first.id,
          uuid: template.documents.first.uuid,
          url: ActiveStorage::Blob.proxy_url(attachment.blob),
          preview_image_url: ActiveStorage::Blob.proxy_url(first_page_blob),
          filename: 'sample-document.pdf'
        }
      ],
      preferences: {
        'request_email_subject' => 'Subject text',
        'request_email_body' => 'Body Text'
      },
      schema: [
        {
          attachment_uuid: template_attachment_uuid,
          name: 'sample-document'
        }
      ],
      author_id: author.id,
      archived_at: nil,
      created_at: template.created_at,
      updated_at: template.updated_at,
      folder_id: folder.id,
      folder_name: folder.name,
      source: 'native',
      external_id: template.external_id,
      application_key: template.external_id # Backward compatibility
    }
  end

  def clone_template_body(cloned_template)
    body = template_body(cloned_template).merge(source: 'api')
    body[:fields].each_with_index do |field, index|
      field.merge!(
        'submitter_uuid' => cloned_template.fields[index]['submitter_uuid'],
        'uuid' => cloned_template.fields[index]['uuid']
      )
    end

    body
  end
end
