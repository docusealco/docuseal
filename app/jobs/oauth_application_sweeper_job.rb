# frozen_string_literal: true

# Sweeper job for abandoned Dynamic Client Registration applications.
#
# Scheduling: this repo has no internal cron (no sidekiq-cron / whenever).
# Schedule externally, e.g. weekly:
#   bin/rails runner 'OauthApplicationSweeperJob.perform_later'
class OauthApplicationSweeperJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = 90.days.ago
    live_app_ids = Doorkeeper::AccessToken.where(revoked_at: nil).select(:application_id)
    Doorkeeper::Application
      .where('created_at < ?', cutoff)
      .where.not(id: live_app_ids)
      .delete_all
  end
end
