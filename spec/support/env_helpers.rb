# frozen_string_literal: true

# Tiny helper to set ENV vars for the duration of a block, then restore.
module EnvHelpers
  def with_env(vars)
    original = {}
    vars.each do |k, v|
      original[k] = ENV.fetch(k, nil)
      if v.nil?
        ENV.delete(k)
      else
        ENV[k] = v
      end
    end
    yield
  ensure
    original.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end

RSpec.configure do |config|
  config.include EnvHelpers
end
