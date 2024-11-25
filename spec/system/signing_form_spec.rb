# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Signing Form', type: :system do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }

  context 'when the template form link is opened' do
    let(:template) { create(:template, account:, author:, except_field_types: %w[phone payment stamp]) }

    before do
      visit start_form_path(slug: template.slug)
    end

    it 'shows the email step', type: :system do
      expect(page).to have_content('You have been invited to submit a form')
      expect(page).to have_content("Invited by #{account.name}")
      expect(page).to have_field('Email', type: 'email')
      expect(page).to have_button('Start')
    end

    it 'completes the form' do
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
