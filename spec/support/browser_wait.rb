# frozen_string_literal: true

wait_time = ENV.fetch('CAPYBARA_MAX_WAIT_TIME', nil)
Capybara.default_max_wait_time = Integer(wait_time) if wait_time
