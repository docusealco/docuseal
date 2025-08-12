# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmittersRequestChangesController, type: :controller do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:template) { create(:template, account: account, author: user) }
  let(:submission) { create(:submission, template: template, account: account, created_by_user: user) }
  let(:submitter) { create(:submitter, submission: submission, account: account, completed_at: 1.hour.ago) }

  before do
    sign_in user
  end

  describe 'GET #request_changes' do
    it 'renders the request changes modal' do
      get :request_changes, params: { slug: submitter.slug }, xhr: true
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #request_changes' do
    context 'when user can request changes' do
      it 'updates submitter and sends notifications' do
        expect do
          post :request_changes, params: { slug: submitter.slug, reason: 'Please fix the signature' }
        end.to change { submitter.reload.changes_requested_at }.from(nil)
           .and change { submitter.reload.completed_at }.to(nil)

        expect(response).to redirect_to(submission_path(submission))
      end

      it 'creates submission event' do
        expect do
          post :request_changes, params: { slug: submitter.slug, reason: 'Fix this' }
        end.to change(SubmissionEvent, :count).by(1)

        event = SubmissionEvent.last
        expect(event.event_type).to eq('request_changes')
        expect(event.data['reason']).to eq('Fix this')
      end
    end

    context 'when user cannot request changes' do
      let(:other_user) { create(:user, account: account) }

      before { sign_in other_user }

      it 'redirects with alert' do
        post :request_changes, params: { slug: submitter.slug, reason: 'Fix this' }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
