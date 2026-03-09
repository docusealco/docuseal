# frozen_string_literal: true

describe 'API Submitters Request Changes' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:submission) { create(:submission, template:, account:, created_by_user: user) }
  let(:submitter) do
    create(
      :submitter,
      submission:,
      account:,
      completed_at: 1.hour.ago,
      uuid: template.submitters.first['uuid']
    )
  end

  describe 'POST /api/submitters/:slug/request_changes' do
    context 'when authenticated with a valid token' do
      it 'clears completed_at and sets changes_requested_at' do
        expect do
          post "/api/submitters/#{submitter.slug}/request_changes",
               headers: { 'x-auth-token': user.access_token.token }
        end.to change { submitter.reload.changes_requested_at }.from(nil)
           .and change { submitter.reload.completed_at }.to(nil)

        expect(response).to have_http_status(:ok)
      end

      it 'is idempotent when changes already requested' do
        submitter.update!(changes_requested_at: 1.hour.ago)

        expect do
          post "/api/submitters/#{submitter.slug}/request_changes",
               headers: { 'x-auth-token': user.access_token.token }
        end.not_to(change { submitter.reload.changes_requested_at })

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when authenticated with a different account token' do
      let(:other_user) { create(:user, account: create(:account)) }

      it 'returns forbidden' do
        post "/api/submitters/#{submitter.slug}/request_changes",
             headers: { 'x-auth-token': other_user.access_token.token }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post "/api/submitters/#{submitter.slug}/request_changes"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
