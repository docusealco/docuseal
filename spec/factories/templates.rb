# frozen_string_literal: true

FactoryBot.define do
  factory :template do
    account

    author factory: %i[user]
    name { Faker::Book.title }

    after(:create) do |template|
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
      template.submitters = [
        {
          'name' => 'First Party',
          'uuid' => '513848eb-1096-4abc-a743-68596b5aaa4c'
        }
      ]
      template.fields = [
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
              'attachment_uuid' => attachment.uuid,
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
      ]

      template.save!
    end
  end
end
