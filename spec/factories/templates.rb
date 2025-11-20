# frozen_string_literal: true

FactoryBot.define do
  factory :template do
    account

    author factory: %i[user]
    name { Faker::Book.title }

    transient do
      submitter_count { 1 }
      attachment_count { 1 }
      only_field_types do
        %w[text date checkbox radio signature number multiple select initials image file stamp cells phone payment]
      end
      except_field_types { [] }
      private_access_user { nil }
    end

    after(:create) do |template, ev|
      number_words = %w[first second third fourth fifth sixth seventh eighth ninth tenth]

      template.submitters = Array.new(ev.submitter_count) do |i|
        {
          'name' => "#{number_words[i]&.capitalize} Party",
          'uuid' => SecureRandom.uuid
        }
      end

      ev.attachment_count.times do |i|
        attachment_index = i + 1 if i > 0
        field_index = "(#{attachment_index})" if attachment_index

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

        template.schema << {
          attachment_uuid: attachment.uuid,
          name: ['sample-document', attachment_index].compact.join('-')
        }

        template.fields += template.submitters.reduce([]) do |fields, submitter|
          fields += [
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['First Name', field_index].compact.join(' '),
              'type' => 'text',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.09273546006944444,
                  'y' => 0.1099851117387033,
                  'w' => 0.2701497395833333,
                  'h' => 0.0372705365913556,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Birthday', field_index].compact.join(' '),
              'type' => 'date',
              'required' => true,
              'preferences' => { 'format' => 'DD/MM/YYYY' },
              'areas' => [
                {
                  'x' => 0.09166666666666666,
                  'y' => 0.1762778204144282,
                  'w' => 0.2763888888888889,
                  'h' => 0.0359029261474578,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Do you agree?', field_index].compact.join(' '),
              'type' => 'checkbox',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.09051106770833334,
                  'y' => 0.227587027259332,
                  'w' => 0.2784450954861111,
                  'h' => 0.04113074042239687,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['First child', field_index].compact.join(' '),
              'type' => 'radio',
              'required' => true,
              'preferences' => {},
              'options' => [
                { 'value' => 'Girl', 'uuid' => SecureRandom.uuid },
                { 'value' => 'Boy', 'uuid' => SecureRandom.uuid }
              ],
              'areas' => [
                {
                  'x' => 0.09027777777777778,
                  'y' => 0.3020184190330008,
                  'w' => 0.2,
                  'h' => 0.02857142857142857,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Signature', field_index].compact.join(' '),
              'type' => 'signature',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.08611111111111111,
                  'y' => 0.3487183422870299,
                  'w' => 0.2,
                  'h' => 0.0707269155206287,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['House number', field_index].compact.join(' '),
              'type' => 'number',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.08333333333333333,
                  'y' => 0.4582041442824252,
                  'w' => 0.2,
                  'h' => 0.02857142857142857,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Colors', field_index].compact.join(' '),
              'type' => 'multiple',
              'required' => true,
              'preferences' => {},
              'options' => [
                { 'value' => 'Red', 'uuid' => SecureRandom.uuid },
                { 'value' => 'Green', 'uuid' => SecureRandom.uuid },
                { 'value' => 'Blue', 'uuid' => SecureRandom.uuid }
              ],
              'areas' => [
                {
                  'x' => 0.45,
                  'y' => 0.1133998465080583,
                  'w' => 0.2,
                  'h' => 0.02857142857142857,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Gender', field_index].compact.join(' '),
              'type' => 'select',
              'required' => true,
              'preferences' => {},
              'options' => [
                { 'value' => 'Male', 'uuid' => SecureRandom.uuid },
                { 'value' => 'Female', 'uuid' => SecureRandom.uuid }
              ],
              'areas' => [
                {
                  'x' => 0.4513888888888889,
                  'y' => 0.1752954719877206,
                  'w' => 0.2,
                  'h' => 0.02857142857142857,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Initials', field_index].compact.join(' '),
              'type' => 'initials',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.4486111111111111,
                  'y' => 0.2273599386032233,
                  'w' => 0.1,
                  'h' => 0.02857142857142857,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Avatar', field_index].compact.join(' '),
              'type' => 'image',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.7180555555555556,
                  'y' => 0.1129547198772064,
                  'w' => 0.2,
                  'h' => 0.1414538310412574,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Attachment', field_index].compact.join(' '),
              'type' => 'file',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.7166666666666667,
                  'y' => 0.3020107444359171,
                  'w' => 0.2,
                  'h' => 0.02857142857142857,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Stamp', field_index].compact.join(' '),
              'type' => 'stamp',
              'required' => true,
              'readonly' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.7166666666666667,
                  'y' => 0.3771910974673829,
                  'w' => 0.2,
                  'h' => 0.0707269155206287,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Cell code', field_index].compact.join(' '),
              'type' => 'cells',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.4472222222222222,
                  'y' => 0.3530851880276286,
                  'w' => 0.2,
                  'h' => 0.02857142857142857,
                  'cell_w' => 0.04,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Payment', field_index].compact.join(' '),
              'type' => 'payment',
              'required' => true,
              'preferences' => { 'currency' => 'EUR', 'price' => 1000 },
              'areas' => [
                {
                  'x' => 0.4486111111111111,
                  'y' => 0.43168073676132,
                  'w' => 0.2,
                  'h' => 0.02857142857142857,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            },
            {
              'uuid' => SecureRandom.uuid,
              'submitter_uuid' => submitter['uuid'],
              'name' => ['Mobile Phone', field_index].compact.join(' '),
              'type' => 'phone',
              'required' => true,
              'preferences' => {},
              'areas' => [
                {
                  'x' => 0.44443359375,
                  'y' => 0.3010283960092095,
                  'w' => 0.2,
                  'h' => 0.02857142857142857,
                  'attachment_uuid' => attachment.uuid,
                  'page' => 0
                }
              ]
            }
          ].select { |f| ev.only_field_types.include?(f['type']) && ev.except_field_types.exclude?(f['type']) }

          fields
        end
      end

      template.save!
    end

    trait :with_admin_only_access do
      after(:create) do |template|
        create(:template_access, template:, user_id: TemplateAccess::ADMIN_USER_ID)
      end
    end

    trait :with_private_access do
      after(:create) do |template, ev|
        create(:template_access, template:, user: ev.private_access_user || template.author)
      end
    end
  end
end
