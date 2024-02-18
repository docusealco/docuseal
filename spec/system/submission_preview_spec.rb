# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Submission Preview' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }

  context 'when not submitted' do
    let(:submission) { create(:submission, template:, created_by_user: user) }
    let(:submitters) { template.submitters.map { |s| create(:submitter, submission:, uuid: s['uuid']) } }

    before do
      sign_in(user)

      visit submissions_preview_path(slug: submission.slug)
    end

    it 'completes the form' do
      expect(page).to have_content('Not completed')
    end
  end
end
