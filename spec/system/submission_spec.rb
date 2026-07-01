# frozen_string_literal: true

RSpec.describe 'Submission' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:submission) do
    create(:submission, :with_submitters, template:, created_by_user: user, archived_at: Time.current)
  end

  before do
    sign_in(user)
    submission.submitters.each { |s| s.update!(completed_at: 1.day.ago) }
  end

  it 'unarchives a completed submission from the download dropdown' do
    visit submission_path(submission)

    find('label[aria-label="Download"]').click
    click_button 'Unarchive'

    expect(page).to have_content('Submission has been unarchived.')
    expect(submission.reload.archived_at).to be_nil
  end
end
