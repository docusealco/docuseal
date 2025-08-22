# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  retry_on StandardError, wait: 6.seconds, attempts: 5 unless Docuseal.multitenant?
end
