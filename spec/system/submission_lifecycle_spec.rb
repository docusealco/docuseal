# frozen_string_literal: true

RSpec.describe 'Submission Lifecycle' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows pending submissions in the template page and completed after signing', sidekiq: :inline do
    create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                              value: GenerateCertificate.call.transform_values(&:to_pem))

    template = create(:template, account:, author: user, only_field_types: %w[text])
    submission = create(:submission, template:)
    submitter = create(:submitter, submission:, uuid: template.submitters.first['uuid'], account:,
                                   email: 'signer@example.com', name: nil)

    visit template_path(template)

    expect(page).to have_content('signer@example.com')
    expect(page).to have_content('AWAITING')

    visit submit_form_path(slug: submitter.slug)

    fill_in 'First Name', with: 'Alice'
    find('#submit_form_button').click

    expect(page).to have_content('Form has been completed!')

    visit template_path(template)

    expect(page).to have_content('signer@example.com')
    expect(page).to have_content('COMPLETED')

    submitter.reload
    expect(submitter.completed_at).to be_present
    expect(submitter.ip).to eq('127.0.0.1')
  end

  it 'creates a submission via the send-to-recipients modal and shows it as pending' do
    template = create(:template, account:, author: user, only_field_types: %w[text])

    visit template_path(template)

    click_link 'Send to Recipients', visible: :all

    within('#modal') do
      find('textarea[name="emails"]').set('recipient@example.com')
      click_button 'Add Recipients'
    end

    expect(page).to have_content('recipient@example.com')
    expect(page).to have_content('AWAITING')

    submission = template.submissions.last
    expect(submission).to be_present
    expect(submission.submitters.first.email).to eq('recipient@example.com')
  end
end
