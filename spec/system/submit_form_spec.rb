# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Submit Form' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:template) { create(:template, account:, author: user) }

  before do
    sign_in(user)
  end

  context 'when initialized by shared link' do
    before do
      visit start_form_path(slug: template.slug)
    end

    it 'shows start form page' do
      expect(page).to have_content('You have been invited to submit a form')
      expect(page).to have_content(template.name)
      expect(page).to have_content("Invited by #{template.account.name}")
    end

    it 'complete the form' do
      fill_in 'Email', with: 'john.dou@example.com'
      click_button 'Start'

      fill_in 'First Name', with: 'Adam'
      click_on 'next'
      click_on 'type_text_button'
      fill_in 'signature_text_input', with: 'Adam'

      expect do
        click_on 'submit'
      end.not_to(change(Submitter, :count))

      submitter = Submitter.find_by(email: 'john.dou@example.com')

      expect(page).to have_button('Download')
      expect(submitter.email).to eq('john.dou@example.com')
      expect(submitter.ip).to eq('127.0.0.1')
      expect(submitter.ua).to be_present
      expect(submitter.opened_at).to be_present
      expect(submitter.completed_at).to be_present
      expect(submitter.values.values).to include('Adam')
    end
  end

  context 'when initialized by shared email address' do
    let!(:submission) { create(:submission, template:, created_by_user: user) }
    let!(:submitters) { template.submitters.map { |s| create(:submitter, submission:, uuid: s['uuid']) } }
    let(:submitter) { submitters.first }

    before do
      visit submit_form_path(slug: submitter.slug)
    end

    it 'completes the form' do
      fill_in 'First Name', with: 'Sally'
      click_on 'next'
      click_on 'type_text_button'
      fill_in 'signature_text_input', with: 'Sally'
      click_on 'submit'

      submitter.reload

      expect(page).to have_button('Download')
      expect(submitter.ip).to eq('127.0.0.1')
      expect(submitter.ua).to be_present
      expect(submitter.opened_at).to be_present
      expect(submitter.completed_at).to be_present
      expect(submitter.values.values).to include('Sally')
    end

    it 'sends completed email' do
      fill_in 'First Name', with: 'Adam'
      click_on 'next'
      click_on 'type_text_button'
      fill_in 'signature_text_input', with: 'Adam'

      expect do
        click_on 'submit'
      end.to change(enqueued_jobs, :size).by(1)
    end
  end
end
