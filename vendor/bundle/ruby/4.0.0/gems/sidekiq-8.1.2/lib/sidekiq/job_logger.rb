# frozen_string_literal: true

module Sidekiq
  class JobLogger
    def initialize(config)
      @config = config
      @logger = @config.logger
      @skip = !!@config[:skip_default_job_logging]
    end

    def call(item, queue)
      start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      @logger.info { "start" } unless @skip

      yield

      Sidekiq::Context.add(:elapsed, elapsed(start))
      @logger.info { "done" } unless @skip
    rescue Exception
      Sidekiq::Context.add(:elapsed, elapsed(start))
      @logger.info { "fail" } unless @skip
      raise
    end

    def prepare(job_hash, &block)
      # If we're using a wrapper class, like ActiveJob, use the "wrapped"
      # attribute to expose the underlying thing.
      h = {
        jid: job_hash["jid"],
        class: job_hash["wrapped"] || job_hash["class"]
      }

      @config[:logged_job_attributes].each do |attr|
        h[attr.to_sym] = job_hash[attr] if job_hash.has_key?(attr)
      end

      Thread.current[:sidekiq_context] = h
      level = job_hash["log_level"]
      if level
        @logger.with_level(level, &block)
      else
        yield
      end
    ensure
      Thread.current[:sidekiq_context] = nil
    end

    private

    def elapsed(start)
      (::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start).round(3)
    end
  end
end
