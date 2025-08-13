# frozen_string_literal: true

require 'rails_helper'

describe 'Request Changes' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:template) { create(:template, account: account, author: user) }
  let(:submission) { create(:submission, template: template, account: account, created_by_user: user) }
  let(:submitter) do
    create(
      :submitter,
      submission: submission,
      account: account,
      completed_at: 1.hour.ago,
      uuid: template.submitters.first['uuid']
    )
  end

  before do
    sign_in user
  end

  describe 'GET /submitters/:slug/request_changes' do
    it 'renders the request changes modal when xhr request' do
      get "/submitters/#{submitter.slug}/request_changes",
          headers: { 'X-Requested-With' => 'XMLHttpRequest' }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /submitters/:slug/request_changes' do
    context 'when user can request changes' do
      it 'updates submitter and sends notifications' do
        expect do
          post "/submitters/#{submitter.slug}/request_changes",
               params: { reason: 'Please fix the signature' }
        end.to change { submitter.reload.changes_requested_at }.from(nil)
           .and change { submitter.reload.completed_at }.to(nil)

        expect(response).to have_http_status(:found)
      end

      it 'creates submission event' do
        expect do
          post "/submitters/#{submitter.slug}/request_changes",
               params: { reason: 'Fix this' }
        end.to change(SubmissionEvent, :count).by(1)

        event = SubmissionEvent.last
        expect(event.event_type).to eq('request_changes')
        expect(event.data['reason']).to eq('Fix this')
      end
    end

    context 'when user cannot request changes' do
      let(:other_user) { create(:user, account: account) }

      before do
        sign_out user
        sign_in other_user
      end

      it 'redirects with alert' do
        post "/submitters/#{submitter.slug}/request_changes",
             params: { reason: 'Fix this' }

        expect(response).to have_http_status(:found)
      end
    end
  end
end
