# frozen_string_literal: true

Rails.application.config.after_initialize do
  status = Submissions::UploadToPaperless.health_check

  if !status[:configured]
    Rails.logger.info('[Paperless-ngx] Integration not configured (PAPERLESS_NGX_URL / PAPERLESS_NGX_TOKEN not set)')
  elsif status[:reachable]
    Rails.logger.info("[Paperless-ngx] Connected to #{status[:url]}")
  else
    Rails.logger.warn("[Paperless-ngx] Configured but unreachable at #{status[:url]}: #{status[:error]}")
  end
rescue StandardError => e
  Rails.logger.warn("[Paperless-ngx] Health check failed during startup: #{e.message}")
end
