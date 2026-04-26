# frozen_string_literal: true

class ProcessAutoArchiveJob
  include Sidekiq::Job

  sidekiq_options retry: 0

  INTERVAL = 24.hours

  def perform
    AccountConfig.where(key: AccountConfig::AUTO_ARCHIVE_DAYS_KEY).find_each do |config|
      days = config.value.to_i
      next if days <= 0

      cutoff = days.days.ago

      Submission.where(account_id: config.account_id)
                .where(archived_at: nil)
                .where(created_at: ...cutoff)
                .find_each do |submission|
        submission.update!(archived_at: Time.current)
        WebhookUrls.enqueue_events(submission, 'submission.archived')
      end
    end
  ensure
    self.class.perform_in(INTERVAL)
  end
end
