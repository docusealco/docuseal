# frozen_string_literal: true

require "date"
require "sidekiq"
require "sidekiq/metrics/shared"

module Sidekiq
  module Metrics
    # Allows caller to query for Sidekiq execution metrics within Redis.
    # Caller sets a set of attributes to act as filters. {#fetch} will call
    # Redis and return a Hash of results.
    #
    # NB: all metrics and times/dates are UTC only. We explicitly do not
    # support timezones.
    class Query
      def initialize(pool: nil, now: Time.now)
        @time = now.utc
        @pool = pool || Sidekiq.default_configuration.redis_pool
        @klass = nil
      end

      ROLLUPS = {
        # minutely aggregates per minute
        minutely: [60, ->(time) { time.strftime("j|%y%m%d|%-H:%M") }],
        # hourly aggregates every 10 minutes so we'll have six data points per hour
        hourly: [600, ->(time) {
          m = time.min
          mins = (m < 10) ? "0" : m.to_s[0]
          time.strftime("j|%y%m%d|%-H:#{mins}")
        }]
      }

      # Get metric data for all jobs from the last hour
      #  +class_filter+: return only results for classes matching filter
      #  +minutes+: the number of fine-grained minute buckets to retrieve
      #  +hours+: the number of coarser-grained 10-minute buckets to retrieve, in hours
      def top_jobs(class_filter: nil, minutes: nil, hours: nil)
        time = @time
        minutes = 60 unless minutes || hours

        # DoS protection, sanity check
        minutes = 60 if minutes && minutes > 480
        hours = 72 if hours && hours > 72

        granularity = hours ? :hourly : :minutely
        result = Result.new(granularity)
        result.ends_at = time
        count = hours ? hours * 6 : minutes
        stride, keyproc = ROLLUPS[granularity]

        redis_results = @pool.with do |conn|
          conn.pipelined do |pipe|
            count.times do |idx|
              key = keyproc.call(time)
              pipe.hgetall key
              time -= stride
            end
          end
        end

        result.starts_at = time
        time = @time
        redis_results.each do |hash|
          hash.each do |k, v|
            kls, metric = k.split("|")
            next if class_filter && !class_filter.match?(kls)
            result.job_results[kls].add_metric metric, time, v.to_i
          end
          time -= stride
        end

        result.marks = fetch_marks(result.starts_at..result.ends_at, granularity)
        result
      end

      def for_job(klass, minutes: nil, hours: nil)
        time = @time
        minutes = 60 unless minutes || hours

        # DoS protection, sanity check
        minutes = 60 if minutes && minutes > 480
        hours = 72 if hours && hours > 72

        granularity = hours ? :hourly : :minutely
        result = Result.new(granularity)
        result.ends_at = time
        count = hours ? hours * 6 : minutes
        stride, keyproc = ROLLUPS[granularity]

        redis_results = @pool.with do |conn|
          conn.pipelined do |pipe|
            count.times do |idx|
              key = keyproc.call(time)
              pipe.hmget key, "#{klass}|ms", "#{klass}|p", "#{klass}|f"
              time -= stride
            end
          end
        end

        result.starts_at = time
        time = @time
        @pool.with do |conn|
          redis_results.each do |(ms, p, f)|
            result.job_results[klass].add_metric "ms", time, ms.to_i if ms
            result.job_results[klass].add_metric "p", time, p.to_i if p
            result.job_results[klass].add_metric "f", time, f.to_i if f
            result.job_results[klass].add_hist time, Histogram.new(klass).fetch(conn, time).reverse if minutes
            time -= stride
          end
        end

        result.marks = fetch_marks(result.starts_at..result.ends_at, granularity)
        result
      end

      class Result < Struct.new(:granularity, :starts_at, :ends_at, :size, :job_results, :marks)
        def initialize(granularity = :minutely)
          super
          self.granularity = granularity
          self.marks = []
          self.job_results = Hash.new { |h, k| h[k] = JobResult.new(granularity) }
        end
      end

      class JobResult < Struct.new(:granularity, :series, :hist, :totals)
        def initialize(granularity = :minutely)
          super
          self.granularity = granularity
          self.series = Hash.new { |h, k| h[k] = Hash.new(0) }
          self.hist = Hash.new { |h, k| h[k] = [] }
          self.totals = Hash.new(0)
        end

        def add_metric(metric, time, value)
          totals[metric] += value
          series[metric][Query.bkt_time_s(time, granularity)] += value

          # Include timing measurements in seconds for convenience
          add_metric("s", time, value / 1000.0) if metric == "ms"
        end

        def add_hist(time, hist_result)
          hist[Query.bkt_time_s(time, granularity)] = hist_result
        end

        def total_avg(metric = "ms")
          completed = totals["p"] - totals["f"]
          return 0 if completed.zero?
          totals[metric].to_f / completed
        end

        def series_avg(metric = "ms")
          series[metric].each_with_object(Hash.new(0)) do |(bucket, value), result|
            completed = series.dig("p", bucket) - series.dig("f", bucket)
            result[bucket] = (completed == 0) ? 0 : value.to_f / completed
          end
        end
      end

      MarkResult = Struct.new(:time, :label, :bucket)

      def self.bkt_time_s(time, granularity)
        # truncate time to ten minutes ("8:40", not "8:43") or one minute
        truncation = (granularity == :hourly) ? 600 : 60
        Time.at(time.to_i - time.to_i % truncation).utc.iso8601
      end

      private

      def fetch_marks(time_range, granularity)
        [].tap do |result|
          marks = @pool.with { |c| c.hgetall("#{@time.strftime("%Y%m%d")}-marks") }

          marks.each do |timestamp, label|
            time = Time.parse(timestamp)
            if time_range.cover? time
              result << MarkResult.new(time, label, Query.bkt_time_s(time, granularity))
            end
          end
        end
      end
    end
  end
end
