# frozen_string_literal: true

RSpec.describe 'Signing Form' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }

  context 'when the template form link is opened' do
    let(:template) do
      create(:template, shared_link: true, account:, author:, except_field_types: %w[phone payment stamp])
    end

    it 'displays only the email step when only email is required' do
      visit start_form_path(slug: template.slug)

      expect(page).to have_content('You have been invited to submit a form')
      expect(page).to have_content("Invited by #{account.name}")
      expect(page).to have_field('Email', type: 'email', placeholder: 'Provide your email to start')
      expect(page).not_to have_field('Phone', type: 'tel')
      expect(page).not_to have_field('Name', type: 'text')
      expect(page).to have_button('Start')
    end

    it 'displays name, email, and phone fields together when all are required' do
      template.update(preferences: { link_form_fields: %w[email name phone] })

      visit start_form_path(slug: template.slug)

      expect(page).to have_content('You have been invited to submit a form')
      expect(page).to have_content("Invited by #{account.name}")
      expect(page).to have_field('Email', type: 'email', placeholder: 'Provide your email')
      expect(page).to have_field('Name', type: 'text', placeholder: 'Provide your name')
      expect(page).to have_field('Phone', type: 'tel', placeholder: 'Provide your phone in international format')
      expect(page).to have_button('Start')
    end

    it 'displays only the name step when only name is required' do
      template.update(preferences: { link_form_fields: %w[name] })

      visit start_form_path(slug: template.slug)

      expect(page).to have_content('You have been invited to submit a form')
      expect(page).to have_content("Invited by #{account.name}")
      expect(page).to have_field('Name', type: 'text', placeholder: 'Provide your name to start')
      expect(page).not_to have_field('Phone', type: 'tel')
      expect(page).not_to have_field('Email', type: 'email')
      expect(page).to have_button('Start')
    end

    it 'displays only the phone step when only phone is required' do
      template.update(preferences: { link_form_fields: %w[phone] })

      visit start_form_path(slug: template.slug)

      expect(page).to have_content('You have been invited to submit a form')
      expect(page).to have_content("Invited by #{account.name}")
      expect(page).to have_field('Phone', type: 'tel',
                                          placeholder: 'Provide your phone in international format to start')
      expect(page).not_to have_field('Name', type: 'text')
      expect(page).not_to have_field('Email', type: 'email')
      expect(page).to have_button('Start')
    end

    it 'prevents starting the form if phone is not in international format' do
      template.update(preferences: { link_form_fields: %w[phone] })

      visit start_form_path(slug: template.slug)

      fill_in 'Phone', with: '12345'

      expect { click_button 'Start' }.not_to(change { current_path })
    end

    it 'prevents starting the form if email is invali' do
      visit start_form_path(slug: template.slug)

      fill_in 'Email', with: 'invalid-email'

      expect { click_button 'Start' }.not_to(change { current_path })
    end

    it 'completes the form' do
      visit start_form_path(slug: template.slug)

      # Submit's email step
      fill_in 'Email', with: 'john.dou@example.com'
      click_button 'Start'

      # Text step
      fill_in 'First Name', with: 'John'
      click_button 'next'

      # Date step
      fill_in 'Birthday', with: I18n.l(20.years.ago, format: '%Y-%m-%d')
      click_button 'next'

      # Checkbox step
      check 'Do you agree?'
      click_button 'next'

      # Radio step
      choose 'Boy'
      click_button 'next'

      # Signature step
      draw_canvas
      click_button 'next'

      # Number step
      fill_in 'House number', with: '123'
      click_button 'next'

      # Multiple choice step
      %w[Red Blue].each { |color| check color }
      click_button 'next'

      # Select step
      select 'Male', from: 'Gender'
      click_button 'next'

      # Initials step
      draw_canvas
      click_button 'next'

      # Image step
      find('#dropzone').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-image.png'))
      click_button 'next'

      # File step
      find('#dropzone').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-document.pdf'))
      click_button 'next'

      # Cell step
      fill_in 'Cell code', with: '123'
      click_on 'Complete'

      expect(page).to have_button('Download')
      expect(page).to have_content('Document has been signed!')

      submitter = template.submissions.last.submitters.last

      expect(submitter.email).to eq('john.dou@example.com')
      expect(submitter.ip).to eq('127.0.0.1')
      expect(submitter.ua).to be_present
      expect(submitter.opened_at).to be_present
      expect(submitter.completed_at).to be_present
      expect(submitter.declined_at).to be_nil

      expect(field_value(submitter, 'First Name')).to eq 'John'
      expect(field_value(submitter, 'Birthday')).to eq 20.years.ago.strftime('%Y-%m-%d')
      expect(field_value(submitter, 'Do you agree?')).to be_truthy
      expect(field_value(submitter, 'First child')).to eq 'Boy'
      expect(field_value(submitter, 'Signature')).to be_present
      expect(field_value(submitter, 'House number')).to eq 123
      expect(field_value(submitter, 'Colors')).to contain_exactly('Red', 'Blue')
      expect(field_value(submitter, 'Gender')).to eq 'Male'
      expect(field_value(submitter, 'Initials')).to be_present
      expect(field_value(submitter, 'Avatar')).to be_present
      expect(field_value(submitter, 'Attachment')).to be_present
      expect(field_value(submitter, 'Cell code')).to eq '123'
    end

    # rubocop:disable RSpec/ExampleLength
    it 'completes the form when name, email, and phone are required' do
      template.update(preferences: { link_form_fields: %w[email name phone] })

      visit start_form_path(slug: template.slug)

      # Submit's name, email, and phone step
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Name', with: 'John Doe'
      fill_in 'Phone', with: '+17732298825'
      click_button 'Start'

      # Text step
      fill_in 'First Name', with: 'John'
      click_button 'next'

      # Date step
      fill_in 'Birthday', with: I18n.l(20.years.ago, format: '%Y-%m-%d')
      click_button 'next'

      # Checkbox step
      check 'Do you agree?'
      click_button 'next'

      # Radio step
      choose 'Boy'
      click_button 'next'

      # Signature step
      draw_canvas
      click_button 'next'

      # Number step
      fill_in 'House number', with: '123'
      click_button 'next'

      # Multiple choice step
      %w[Red Blue].each { |color| check color }
      click_button 'next'

      # Select step
      select 'Male', from: 'Gender'
      click_button 'next'

      # Initials step
      draw_canvas
      click_button 'next'

      # Image step
      find('#dropzone').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-image.png'))
      click_button 'next'

      # File step
      find('#dropzone').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-document.pdf'))
      click_button 'next'

      # Cell step
      fill_in 'Cell code', with: '123'
      click_on 'Complete'

      expect(page).to have_button('Download')
      expect(page).to have_content('Document has been signed!')

      submitter = template.submissions.last.submitters.last

      expect(submitter.email).to eq('john.dou@example.com')
      expect(submitter.name).to eq('John Doe')
      expect(submitter.phone).to eq('+17732298825')
      expect(submitter.ip).to eq('127.0.0.1')
      expect(submitter.ua).to be_present
      expect(submitter.opened_at).to be_present
      expect(submitter.completed_at).to be_present
      expect(submitter.declined_at).to be_nil

      expect(field_value(submitter, 'First Name')).to eq 'John'
      expect(field_value(submitter, 'Birthday')).to eq 20.years.ago.strftime('%Y-%m-%d')
      expect(field_value(submitter, 'Do you agree?')).to be_truthy
      expect(field_value(submitter, 'First child')).to eq 'Boy'
      expect(field_value(submitter, 'Signature')).to be_present
      expect(field_value(submitter, 'House number')).to eq 123
      expect(field_value(submitter, 'Colors')).to contain_exactly('Red', 'Blue')
      expect(field_value(submitter, 'Gender')).to eq 'Male'
      expect(field_value(submitter, 'Initials')).to be_present
      expect(field_value(submitter, 'Avatar')).to be_present
      expect(field_value(submitter, 'Attachment')).to be_present
      expect(field_value(submitter, 'Cell code')).to eq '123'
    end
    # rubocop:enable RSpec/ExampleLength
  end

  context 'when the submitter form link is opened' do
    let(:template) { create(:template, account:, author:, except_field_types: %w[phone payment stamp]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:, email: 'robin@example.com')
    end

    before do
      visit submit_form_path(slug: submitter.slug)
    end

    it 'complete the form' do
      # Text step
      fill_in 'First Name', with: 'John'
      click_button 'next'

      # Date step
      fill_in 'Birthday', with: I18n.l(20.years.ago, format: '%Y-%m-%d')
      click_button 'next'

      # Checkbox step
      check 'Do you agree?'
      click_button 'next'

      # Radio step
      choose 'Boy'
      click_button 'next'

      # Signature step
      draw_canvas
      click_button 'next'

      # Number step
      fill_in 'House number', with: '123'
      click_button 'next'

      # Multiple choice step
      %w[Red Blue].each { |color| check color }
      click_button 'next'

      # Select step
      select 'Male', from: 'Gender'
      click_button 'next'

      # Initials step
      draw_canvas
      click_button 'next'

      # Image step
      find('#dropzone').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-image.png'))
      click_button 'next'

      # File step
      find('#dropzone').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-document.pdf'))
      click_button 'next'

      # Cell step
      fill_in 'Cell code', with: '123'
      click_on 'Complete'

      expect(page).to have_button('Download')
      expect(page).to have_content('Document has been signed!')

      submitter.reload

      expect(submitter.email).to eq 'robin@example.com'
      expect(submitter.ip).to eq('127.0.0.1')
      expect(submitter.ua).to be_present
      expect(submitter.opened_at).to be_present
      expect(submitter.completed_at).to be_present
      expect(submitter.declined_at).to be_nil

      expect(field_value(submitter, 'First Name')).to eq 'John'
      expect(field_value(submitter, 'Birthday')).to eq 20.years.ago.strftime('%Y-%m-%d')
      expect(field_value(submitter, 'Do you agree?')).to be_truthy
      expect(field_value(submitter, 'First child')).to eq 'Boy'
      expect(field_value(submitter, 'Signature')).to be_present
      expect(field_value(submitter, 'House number')).to eq 123
      expect(field_value(submitter, 'Colors')).to contain_exactly('Red', 'Blue')
      expect(field_value(submitter, 'Gender')).to eq 'Male'
      expect(field_value(submitter, 'Initials')).to be_present
      expect(field_value(submitter, 'Avatar')).to be_present
      expect(field_value(submitter, 'Attachment')).to be_present
      expect(field_value(submitter, 'Cell code')).to eq '123'
    end
  end

  context 'when the text step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[text]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the field is filled' do
      visit submit_form_path(slug: submitter.slug)

      input = find_field('First Name')

      expect(input[:required]).to be_truthy
      expect(input[:placeholder]).to eq 'Type here...'

      fill_in 'First Name', with: 'Mary'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'First Name')).to eq 'Mary'
    end

    it 'toggle multiple text button' do
      visit submit_form_path(slug: submitter.slug)

      input = find_field('First Name')

      expect(input.tag_name).to eq('input')

      find(:css, 'div[data-tip="Toggle Multiline Text"]').click

      input = find_field('First Name')

      expect(input.tag_name).to eq('textarea')
      expect(page).not_to have_selector(:css, 'div[data-tip="Toggle Multiline Text"]')

      fill_in 'First Name', with: 'Very long text'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(field_value(submitter, 'First Name')).to eq 'Very long text'
      expect(submitter.completed_at).to be_present
    end
  end

  context 'when the date step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[date]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the field is filled' do
      visit submit_form_path(slug: submitter.slug)

      input = find_field('Birthday')

      expect(input[:required]).to be_truthy

      fill_in 'Birthday', with: I18n.l(25.years.ago, format: '%Y-%m-%d')
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Birthday')).to eq 25.years.ago.strftime('%Y-%m-%d')
    end

    it 'pre-fills the current date into the form field' do
      visit submit_form_path(slug: submitter.slug)

      input = find_field('Birthday')

      expect(input[:value]).to eq ''

      click_button 'Set Today'

      input = find_field('Birthday')

      expect(input[:value]).to eq Time.zone.now.strftime('%Y-%m-%d')

      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Birthday')).to eq Time.zone.now.strftime('%Y-%m-%d')
    end
  end

  context 'when the checkbox step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[checkbox]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the checkbox is checked' do
      visit submit_form_path(slug: submitter.slug)

      check 'Do you agree?'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Do you agree?')).to be true
    end
  end

  context 'when the radio step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[radio]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the checkbox is checked' do
      visit submit_form_path(slug: submitter.slug)

      %w[Girl Boy].map { |v| find_field(v) }.each { |input| expect(input[:required]).to be_truthy }

      choose 'Boy'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'First child')).to eq 'Boy'
    end
  end

  context 'when the signature step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[signature]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the canvas is drawn' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      draw_canvas
      click_button 'Sign and Complete'

      expect(page).to have_content('Document has been signed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Signature')).to be_present
    end

    it 'shows an error message if the canvas is not drawn or too simple' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      page.find('canvas').click([], { x: 150, y: 100 })

      alert_text = page.accept_alert do
        click_button 'Sign and Complete'
      end

      expect(alert_text).to eq 'Signature is too small or simple. Please redraw.'
    end

    it 'completes the form if the canvas is typed' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      click_link 'Type'
      fill_in 'signature_text_input', with: 'John Doe'
      click_button 'Sign and Complete'

      expect(page).to have_content('Document has been signed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Signature')).to be_present
    end
  end

  context 'when the number step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[number]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the field is filled' do
      visit submit_form_path(slug: submitter.slug)

      input = find_field('House number')

      expect(input[:required]).to be_truthy
      expect(input[:placeholder]).to eq 'Type here...'

      fill_in 'House number', with: '4'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'House number')).to eq 4
    end
  end

  context 'when the multiple choice step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[multiple]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the multiple choice is checked' do
      visit submit_form_path(slug: submitter.slug)

      %w[Red Green].each { |color| check color }
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Colors')).to contain_exactly('Red', 'Green')
    end
  end

  context 'when the select step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[select]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the multiple choice is checked' do
      visit submit_form_path(slug: submitter.slug)

      select 'Female', from: 'Gender'

      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Gender')).to eq 'Female'
    end
  end

  context 'when the initials step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[initials]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the canvas is typed' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      fill_in 'initials_text_input', with: 'John Doe'
      click_button 'Complete'

      expect(page).to have_content('Document has been signed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Initials')).to be_present
    end

    it 'completes the form if the canvas is drawn' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      click_link 'Draw'
      draw_canvas
      click_button 'Complete'

      expect(page).to have_content('Document has been signed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Initials')).to be_present
    end

    it 'completes the form if the initials is uploaded' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      find('span[data-tip="Click to upload"]').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-image.png'))

      sleep 0.1

      click_button 'Complete'

      expect(page).to have_content('Document has been signed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Initials')).to be_present
    end
  end

  context 'when the image step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[image]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the image is uploaded' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      find('#dropzone').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-image.png'))
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Avatar')).to be_present
    end
  end

  context 'when the file step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[file]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the file is uploaded' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      find('#dropzone').click
      find('input[type="file"]', visible: false).attach_file(Rails.root.join('spec/fixtures/sample-document.pdf'))
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Attachment')).to be_present
    end
  end

  context 'when the cells step' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[cells]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes the form if the field is filled' do
      visit submit_form_path(slug: submitter.slug)

      input = find_field('Cell code')

      expect(input[:required]).to be_truthy
      expect(input[:placeholder]).to eq 'Type here...'

      fill_in 'Cell code', with: '456'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Cell code')).to eq '456'
    end
  end

  context 'when the field with conditions' do
    let(:template) { create(:template, account:, author:, only_field_types: ['text']) }
    let(:submission) { create(:submission, :with_submitters, template:) }
    let(:template_attachment) { template.schema.first }
    let(:template_submitter) { submission.template_submitters.first }
    let(:submitter) { submission.submitters.first }
    let(:fields) do
      [
        {
          'uuid' => 'da7e0d56-fdb0-441a-bbed-d0f6f2e10fd6',
          'submitter_uuid' => submitter.uuid,
          'name' => 'Full Name',
          'type' => 'text',
          'required' => false,
          'preferences' => {},
          'conditions' => [],
          'areas' => [
            {
              'x' => 0.1117351575121163,
              'y' => 0.08950650415231329,
              'w' => 0.2,
              'h' => 0.02857142857142857,
              'attachment_uuid' => template_attachment['attachment_uuid'],
              'page' => 0
            }
          ]
        },
        {
          'uuid' => 'd32ad52a-8f6b-4e32-b0d6-6258fb47440b',
          'submitter_uuid' => submitter.uuid,
          'name' => 'Email',
          'type' => 'text',
          'required' => false,
          'preferences' => {},
          'conditions' => [],
          'validation' => { 'pattern' => '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$' },
          'areas' => [
            {
              'x' => 0.1097914983844911,
              'y' => 0.1417641720258019,
              'w' => 0.2,
              'h' => 0.02857142857142857,
              'attachment_uuid' => template_attachment['attachment_uuid'],
              'page' => 0
            }
          ]
        },
        {
          'uuid' => 'c6e013ae-f9f6-4b3a-ad33-b7e772a0a49f',
          'submitter_uuid' => submitter.uuid,
          'name' => 'Phone',
          'type' => 'text',
          'required' => false,
          'preferences' => {},
          'areas' => [
            {
              'x' => 0.1100060581583199,
              'y' => 0.2553160344676159,
              'w' => 0.2,
              'h' => 0.02857142857142857,
              'attachment_uuid' => template_attachment['attachment_uuid'],
              'page' => 0
            }
          ]
        },
        {
          'uuid' => '64523936-22fd-41f8-b997-ede8fbe467cc',
          'submitter_uuid' => submitter.uuid,
          'name' => 'Comment',
          'type' => 'text',
          'required' => false,
          'preferences' => {},
          'conditions' => [
            { 'field_uuid' => 'da7e0d56-fdb0-441a-bbed-d0f6f2e10fd6', 'action' => 'not_empty' },
            { 'field_uuid' => 'd32ad52a-8f6b-4e32-b0d6-6258fb47440b', 'action' => 'not_empty' },
            { 'field_uuid' => 'c6e013ae-f9f6-4b3a-ad33-b7e772a0a49f', 'action' => 'not_empty', 'operation' => 'or' }
          ],
          'areas' => [
            {
              'x' => 0.1145875403877221,
              'y' => 0.1982961365432846,
              'w' => 0.2,
              'h' => 0.02857142857142857,
              'attachment_uuid' => template_attachment['attachment_uuid'],
              'page' => 0
            }
          ]
        }
      ]
    end

    before do
      template.update(fields:)
      submission.update(template_fields: fields)
    end

    it 'completes the form and saves the conditional field when all required fields are filled' do
      visit submit_form_path(slug: submitter.slug)
      fill_in 'Full Name (optional)', with: 'John Doe'
      click_button 'next'

      fill_in 'Email (optional)', with: 'john.due@example.com'
      click_button 'next'

      fill_in 'Phone (optional)', with: '+1 (773) 229-8825'
      click_button 'next'

      fill_in 'Comment', with: 'This is a comment'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Full Name')).to eq 'John Doe'
      expect(field_value(submitter, 'Email')).to eq 'john.due@example.com'
      expect(field_value(submitter, 'Phone')).to eq '+1 (773) 229-8825'
      expect(field_value(submitter, 'Comment')).to eq 'This is a comment'
    end

    it 'completes the form and saves the conditional field when minimum required fields are filled' do
      visit submit_form_path(slug: submitter.slug)
      fill_in 'Full Name (optional)', with: 'John Doe'
      click_button 'next'

      fill_in 'Email (optional)', with: 'john.due@example.com'
      click_button 'next'

      fill_in 'Phone (optional)', with: ''
      click_button 'next'

      fill_in 'Comment', with: 'This is a comment'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Full Name')).to eq 'John Doe'
      expect(field_value(submitter, 'Email')).to eq 'john.due@example.com'
      expect(field_value(submitter, 'Phone')).to be_empty
      expect(field_value(submitter, 'Comment')).to eq 'This is a comment'
    end

    it 'completes the form without saving the conditional field when not enough fields are filled' do
      visit submit_form_path(slug: submitter.slug)

      fill_in 'Full Name (optional)', with: 'Jane Doe'
      click_button 'next'

      fill_in 'Email (optional)', with: ''
      click_button 'next'

      fill_in 'Phone (optional)', with: ''
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Full Name')).to eq 'Jane Doe'
      expect(field_value(submitter, 'Email')).to be_empty
      expect(field_value(submitter, 'Phone')).to be_empty
      expect(field_value(submitter, 'Comment')).to be_nil
    end

    it 'completes the form without saving the conditional field when only partial fields are filled' do
      visit submit_form_path(slug: submitter.slug)

      fill_in 'Full Name (optional)', with: ''
      click_button 'next'

      fill_in 'Email (optional)', with: 'john.due@example.com'
      click_button 'next'

      fill_in 'Phone (optional)', with: '+1 (773) 229-8825'
      click_button 'Complete'

      expect(page).to have_content('Form has been completed!')

      submitter.reload

      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Full Name')).to be_empty
      expect(field_value(submitter, 'Email')).to eq 'john.due@example.com'
      expect(field_value(submitter, 'Phone')).to eq '+1 (773) 229-8825'
      expect(field_value(submitter, 'Comment')).to be_nil
    end
  end

  context 'when the masked field' do
    let(:template) { create(:template, submitter_count: 2, account:, author:, only_field_types: %w[text]) }
    let(:submission) { create(:submission, template: template) }
    let!(:first_submitter) { create(:submitter, submission:, uuid: template.submitters[0]['uuid'], account:) }
    let!(:second_submitter) { create(:submitter, submission:, uuid: template.submitters[1]['uuid'], account:) }

    it 'shows the masked value instead of the real value' do
      field = submission.template_fields.find do |f|
        f['name'] == 'First Name' && f['submitter_uuid'] == first_submitter.uuid
      end
      field['preferences']['mask'] = true
      submission.save!

      visit submit_form_path(slug: first_submitter.slug)

      fill_in 'First Name', with: 'Jahn'
      click_button 'Complete'

      visit submit_form_path(slug: second_submitter.slug)

      expect(page).to have_content('XXXX')
    end
  end

  context 'when the template requires multiple submitters' do
    let(:template) do
      create(:template, shared_link: true, submitter_count: 2, account:, author:, only_field_types: %w[text])
    end

    context 'when default signer details are not defined' do
      it 'shows an explanation error message if a logged-in user associated with the template account opens the link' do
        sign_in author
        visit start_form_path(slug: template.slug)
        fill_in 'Email', with: author.email
        click_button 'Start'

        expect(page).to have_content('This submission has multiple signers, which prevents the use of a sharing link ' \
                                     "as it's unclear which signer is responsible for specific fields. " \
                                     'To resolve this, follow this guide to define the default signer details.')
        expect(page).to have_link('guide', href: 'https://www.docuseal.com/resources/pre-filling-recipients')
      end

      it 'shows a "Not found" error message if a logged-out user associated with the template account opens the link' do
        visit start_form_path(slug: template.slug)
        fill_in 'Email', with: author.email
        click_button 'Start'

        expect(page).to have_content('Not found')
      end

      it 'shows a "Not found" error message if an unrelated user opens the link' do
        visit start_form_path(slug: template.slug)
        fill_in 'Email', with: 'john.doe@example.com'
        click_button 'Start'

        expect(page).to have_content('Not found')
      end
    end
  end

  context 'when the template shared link is disabled' do
    let(:template) do
      create(:template, shared_link: false, account:, author:, only_field_types: %w[text])
    end

    context 'when user is logged in' do
      before do
        login_as author
        visit start_form_path(slug: template.slug)
      end

      it 'shows a warning that the shared link is disabled and provides an option to enable it' do
        expect(page).to have_content('Share link is currently disabled')
        expect(page).to have_content(template.name)
        expect(page).to have_button('Enable shared link')
      end

      it 'enables the shared link' do
        expect do
          click_button 'Enable shared link'
        end.to change { template.reload.shared_link }.from(false).to(true)

        expect(page).to have_content('You have been invited to submit a form')
      end
    end
  end

  it 'sends completed email' do
    template = create(:template, account:, author:, only_field_types: %w[text signature])
    submission = create(:submission, template:)
    submitter = create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)

    visit submit_form_path(slug: submitter.slug)

    fill_in 'First Name', with: 'Adam'
    click_on 'next'
    click_link 'Type'
    fill_in 'signature_text_input', with: 'Adam'

    expect do
      click_on 'Sign and Complete'
    end.to change(ProcessSubmitterCompletionJob.jobs, :size).by(1)
  end
end
