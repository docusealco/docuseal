# frozen_string_literal: true

begin
  gem "activejob", ">= 7.0"
  require "active_job"

  module Sidekiq
    module ActiveJob
      # @api private
      class Wrapper
        include Sidekiq::Job

        def perform(job_data)
          ::ActiveJob::Base.execute(job_data.merge("provider_job_id" => jid))
        end
      end
    end
  end

  ActiveSupport.on_load(:active_job) do
    # By including the Options module, we allow AJs to directly control sidekiq features
    # via the *sidekiq_options* class method and, for instance, not use AJ's retry system.
    # AJ retries don't show up in the Sidekiq UI Retries tab, don't save any error data, can't be
    # manually retried, don't automatically die, etc.
    #
    #   class SomeJob < ActiveJob::Base
    #     queue_as :default
    #     sidekiq_options retry: 3, backtrace: 10
    #     def perform
    #     end
    #   end
    include Sidekiq::Job::Options unless respond_to?(:sidekiq_options)
  end

  # Patch the ActiveJob module
  module ActiveJob
    module QueueAdapters
      # Explicitly remove the implementation existing in older Rails.
      remove_const(:SidekiqAdapter) if const_defined?(:SidekiqAdapter)

      # Sidekiq adapter for Active Job
      #
      # To use Sidekiq set the queue_adapter config to +:sidekiq+.
      #
      #   Rails.application.config.active_job.queue_adapter = :sidekiq
      parent = const_defined?(:AbstractAdapter) ? AbstractAdapter : Object
      class SidekiqAdapter < parent
        @@stopping = false

        callback = -> { @@stopping = true }

        Sidekiq.configure_client { |config| config.on(:quiet, &callback) }
        Sidekiq.configure_server { |config| config.on(:quiet, &callback) }

        # Defines whether enqueuing should happen implicitly to after commit when called
        # from inside a transaction.
        # @api private
        def enqueue_after_transaction_commit?
          true
        end

        # @api private
        def enqueue(job)
          # NB: Active Job only serializes keys it recognizes. We
          # cannot set arbitrary key/values here.
          options = {wrapped: job.class, queue: job.queue_name}
          options[:profile] = job.profile if job.respond_to?(:profile) && !job.profile.nil?

          wrapper = Sidekiq::ActiveJob::Wrapper.set(options)
          job.provider_job_id = wrapper.perform_async(job.serialize)
        end

        # @api private
        def enqueue_at(job, timestamp)
          options = {wrapped: job.class, queue: job.queue_name}
          options[:profile] = job.profile if job.respond_to?(:profile) && !job.profile.nil?

          job.provider_job_id = Sidekiq::ActiveJob::Wrapper.set(options).perform_at(timestamp, job.serialize)
        end

        # @api private
        def enqueue_all(jobs)
          enqueued_count = 0
          jobs.group_by(&:class).each do |job_class, same_class_jobs|
            same_class_jobs.group_by(&:queue_name).each do |queue, same_class_and_queue_jobs|
              immediate_jobs, scheduled_jobs = same_class_and_queue_jobs.partition { |job| job.scheduled_at.nil? }

              if immediate_jobs.any?
                jids = Sidekiq::Client.push_bulk(
                  "class" => Sidekiq::ActiveJob::Wrapper,
                  "wrapped" => job_class,
                  "queue" => queue,
                  "args" => immediate_jobs.map { |job| [job.serialize] }
                )
                enqueued_count += jids.compact.size
              end

              if scheduled_jobs.any?
                jids = Sidekiq::Client.push_bulk(
                  "class" => Sidekiq::ActiveJob::Wrapper,
                  "wrapped" => job_class,
                  "queue" => queue,
                  "args" => scheduled_jobs.map { |job| [job.serialize] },
                  "at" => scheduled_jobs.map { |job| job.scheduled_at&.to_f }
                )
                enqueued_count += jids.compact.size
              end
            end
          end
          enqueued_count
        end

        # @api private
        def stopping? = !!@@stopping

        # Defines a class alias for backwards compatibility with enqueued Active Job jobs.
        # @api private
        JobWrapper = Sidekiq::ActiveJob::Wrapper
      end
    end
  end
rescue Gem::LoadError
  # ActiveJob not available or version requirement not met
end
