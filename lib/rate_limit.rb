# frozen_string_literal: true

module RateLimit
  LimitApproached = Class.new(StandardError)

  STORE = ActiveSupport::Cache::MemoryStore.new

  module_function

  def call(key, limit:, ttl:, enabled: Docuseal.multitenant?)
    return true unless enabled

    value = STORE.increment(key, 1, expires_in: ttl)

    raise LimitApproached if value > limit

    true
  end
end
