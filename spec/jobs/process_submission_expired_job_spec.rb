# frozen_string_literal: true

RSpec.describe ProcessSubmissionExpiredJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:expire_at) { 2.days.from_now.change(usec: 0) }
  let(:submission) do
    create(:submission, :with_submitters, template:, created_by_user: user, expire_at:)
  end

  before { allow(WebhookUrls).to receive(:enqueue_events) }

  describe '#perform' do
    it 'enqueues the expired event when the scheduled expire_at still matches' do
      described_class.new.perform('submission_id' => submission.id, 'expire_at' => expire_at.to_i)

      expect(WebhookUrls).to have_received(:enqueue_events).with(submission, 'submission.expired')
    end

    it 'enqueues the expired event for legacy jobs scheduled without an expire_at param' do
      described_class.new.perform('submission_id' => submission.id)

      expect(WebhookUrls).to have_received(:enqueue_events).with(submission, 'submission.expired')
    end

    it 'skips a stale job scheduled for an earlier expire_at that was extended' do
      submission.update!(expire_at: 3.days.from_now)

      described_class.new.perform('submission_id' => submission.id, 'expire_at' => expire_at.to_i)

      expect(WebhookUrls).not_to have_received(:enqueue_events)
    end

    it 'skips a stale job scheduled for a later expire_at that was shortened' do
      submission.update!(expire_at: 1.day.from_now)

      described_class.new.perform('submission_id' => submission.id, 'expire_at' => expire_at.to_i)

      expect(WebhookUrls).not_to have_received(:enqueue_events)
    end

    it 'skips a stale job when the expiration has been cleared' do
      submission.update!(expire_at: nil)

      described_class.new.perform('submission_id' => submission.id, 'expire_at' => expire_at.to_i)

      expect(WebhookUrls).not_to have_received(:enqueue_events)
    end
  end
end
