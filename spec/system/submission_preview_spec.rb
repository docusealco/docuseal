# frozen_string_literal: true

RSpec.describe 'Submission Preview' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }

  context 'when not submitted' do
    let(:submission) { create(:submission, :with_submitters, template:, created_by_user: user) }

    context 'when user is signed in' do
      before do
        sign_in(user)

        visit submissions_preview_path(slug: submission.slug)
      end

      it 'completes the form' do
        expect(page).to have_content('Not completed')
      end
    end

    context 'when user is not signed in' do
      context 'when submission is not completed' do
        before do
          create(:encrypted_config, account:, key: EncryptedConfig::EMAIL_SMTP_KEY, value: '{}')

          submission.submitters.each { |s| s.update(completed_at: 1.day.ago) }

          visit submissions_preview_path(slug: submission.slug)
        end

        it "sends a copy to the submitter's email" do
          fill_in 'Email', with: submission.submitters.first.email
          click_button 'Send copy to Email'

          expect(page).to have_content('Email has been sent.')
        end

        it 'shows an error for an email not associated with the submission' do
          fill_in 'Email', with: 'john.due@example.com'
          click_button 'Send copy to Email'

          expect(page).to have_content('Please enter your email address associated with the completed submission.')
        end
      end

      it "doesn't display the email form if SMTP is not configured" do
        submission.submitters.each { |s| s.update(completed_at: 1.day.ago) }

        visit submissions_preview_path(slug: submission.slug)

        expect(page).to have_content(template.name)
        expect(page).not_to have_field('Email')
        expect(page).not_to have_content('Send copy to Email')
      end
    end
  end
end
