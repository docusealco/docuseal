# frozen_string_literal: true

FactoryBot.define do
  factory :template do
    account

    author factory: %i[user]
    name { Faker::Book.title }

    transient do
      submitter_count { 1 }
    end

    after(:create) do |template, evaluator|
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join('spec/fixtures/sample-document.pdf').open,
        filename: 'sample-document.pdf',
        content_type: 'application/pdf'
      )
      attachment = ActiveStorage::Attachment.create!(
        blob:,
        name: :documents,
        record: template
      )

      Templates::ProcessDocument.call(attachment, attachment.download)

      template.schema = [{ attachment_uuid: attachment.uuid, name: 'sample-document' }]
      number_words = %w[first second third fourth fifth sixth seventh eighth ninth tenth]

      template.submitters = Array.new(evaluator.submitter_count) do |i|
        {
          'name' => "#{number_words[i]&.capitalize} Party",
          'uuid' => SecureRandom.uuid
        }
      end

      template.fields = template.submitters.reduce([]) do |fields, submitter|
        fields += [
          {
            'uuid' => SecureRandom.uuid,
            'submitter_uuid' => submitter['uuid'],
            'name' => 'First Name',
            'type' => 'text',
            'required' => true,
            'areas' => [
              {
                'x' => 0.09027777777777778,
                'y' => 0.1197252208047105,
                'w' => 0.3069444444444444,
                'h' => 0.03336604514229637,
                'attachment_uuid' => attachment.uuid,
                'page' => 0
              }
            ]
          },
          {
            'uuid' => SecureRandom.uuid,
            'submitter_uuid' => submitter['uuid'],
            'name' => '',
            'type' => 'signature',
            'required' => true,
            'areas' => []
          }
        ]

        fields
      end

      template.save!
    end
  end
end
