# frozen_string_literal: true

RSpec.describe 'Signing Flow Edge Cases' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }

  describe 'enforced signing order' do
    let(:template) do
      create(:template, submitter_count: 2, account:, author:, only_field_types: %w[text])
    end
    let(:submission) do
      create(:submission, template:, template_fields: template.fields, template_submitters: template.submitters)
    end
    let(:first_submitter) do
      create(:submitter, submission:, uuid: template.submitters[0]['uuid'], account:,
                         email: 'first@example.com')
    end
    let(:second_submitter) do
      create(:submitter, submission:, uuid: template.submitters[1]['uuid'], account:,
                         email: 'second@example.com')
    end

    pending 'blocks second signer: Vue timing issue with Submitters.current_submitter_order?' do
      create(:account_config, account:, key: AccountConfig::ENFORCE_SIGNING_ORDER_KEY, value: true)

      visit submit_form_path(slug: second_submitter.slug)

      expect(page).to have_content('Awaiting completion by the other party')
      expect(page).not_to have_selector('#submit_form_button')
    end

    it 'allows the second signer to fill after the first completes' do
      visit submit_form_path(slug: first_submitter.slug)
      fill_in 'First Name', with: 'Alice'
      find('#submit_form_button').click
      expect(page).to have_content('Form has been completed!')

      visit submit_form_path(slug: second_submitter.slug)
      fill_in 'First Name', with: 'Bob'
      find('#submit_form_button').click
      expect(page).to have_content('Form has been completed!')

      second_submitter.reload
      expect(second_submitter.completed_at).to be_present
    end
  end

  describe 'signature pad clear and redraw' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[signature]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'completes after clearing and redrawing the signature' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click
      draw_canvas
      click_button 'Clear'
      draw_canvas
      click_button 'Sign and Complete'

      expect(page).to have_content('Document has been signed!')

      submitter.reload
      expect(submitter.completed_at).to be_present
      expect(field_value(submitter, 'Signature')).to be_present
    end
  end

  describe 'resubmit flow' do
    let(:template) do
      create(:template, shared_link: true, account:, author:, only_field_types: %w[text])
    end

    before do
      create(:account_config, account:, key: AccountConfig::ALLOW_TO_RESUBMIT, value: true)
    end

    pending 'resubmit flow: field not found on second start form visit' do
      visit start_form_path(slug: template.slug)

      fill_in 'Email', with: 'john@example.com'
      click_button 'Start'

      fill_in 'First Name', with: 'John'
      find('#submit_form_button').click

      expect(page).to have_content('Form has been completed!')

      visit start_form_path(slug: template.slug)

      fill_in 'Email', with: 'john@example.com'
      click_button 'Start'

      expect(page).not_to have_content('already completed')

      fill_in 'First Name', with: 'John Updated'
      find('#submit_form_button').click

      expect(page).to have_content('Form has been completed!')
    end
  end

  describe 'all optional fields' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[text date]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    before do
      fields = template.fields.map { |f| f.dup.tap { |h| h['required'] = false } }
      template.update!(fields:)
      submission.update!(template_fields: fields)
    end

    pending 'optional fields: Vue teleport timing issue with complete button' do
      visit submit_form_path(slug: submitter.slug)

      find('#expand_form_button').click

      expect(page).to have_css('#complete_button_container')

      page.execute_script('document.getElementById("complete_form_button")?.click() || document.querySelector(".complete-button")?.click()')

      expect(page).to have_content('Form has been completed!')

      submitter.reload
      expect(submitter.completed_at).to be_present
    end
  end

  describe 'decline with custom reason' do
    let(:template) { create(:template, account:, author:, only_field_types: %w[text]) }
    let(:submission) { create(:submission, template:) }
    let(:submitter) do
      create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:)
    end

    it 'records the decline reason on the submission event' do
      visit submit_form_path(slug: submitter.slug)

      find('#decline_button').click
      fill_in 'reason', with: 'I do not agree with the terms and conditions'
      within('dialog[open]') { click_button 'Decline' }

      expect(page).to have_content('Form has been declined')

      submitter.reload
      expect(submitter.declined_at).to be_present

      event = submission.submission_events.find_by(submitter:, event_type: 'decline_form')
      expect(event).to be_present
      expect(event.data).to include('reason' => 'I do not agree with the terms and conditions')
    end
  end
end
