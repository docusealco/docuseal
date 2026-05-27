require "fileutils"
require "sidekiq/component"

module Sidekiq
  # Allows the user to profile jobs running in production.
  # See details in the Profiling wiki page.
  class Profiler
    EXPIRY = 86400 # 1 day
    DEFAULT_OPTIONS = {
      mode: :wall
    }

    include Sidekiq::Component

    def initialize(config)
      @config = config
      @vernier_output_dir = ENV.fetch("VERNIER_OUTPUT_DIR") { Dir.tmpdir }
    end

    def call(job, &block)
      return yield unless job["profile"]

      token = job["profile"]
      type = job["wrapped"] || job["class"]
      jid = job["jid"]
      started_at = Time.now

      rundata = {
        started_at: started_at.to_i,
        token: token,
        type: type,
        jid: jid,
        # .gz extension tells Vernier to compress the data
        filename: File.join(
          @vernier_output_dir,
          "#{token}-#{type}-#{jid}-#{started_at.strftime("%Y%m%d-%H%M%S")}.json.gz"
        )
      }
      profiler_options = profiler_options(job, rundata)

      require "vernier"
      begin
        a = Time.now
        rc = Vernier.profile(**profiler_options, &block)
        b = Time.now

        # Failed jobs will raise an exception on previous line and skip this
        # block. Only successful jobs will persist profile data to Redis.
        key = "#{token}-#{jid}"
        data = File.read(rundata[:filename])
        redis do |conn|
          conn.multi do |m|
            m.zadd("profiles", Time.now.to_f + EXPIRY, key)
            m.hset(key, rundata.merge(elapsed: (b - a), data: data, size: data.bytesize))
            m.expire(key, EXPIRY)
          end
        end
        rc
      ensure
        FileUtils.rm_f(rundata[:filename])
      end
    end

    private

    def profiler_options(job, rundata)
      profiler_options = (job["profiler_options"] || {}).transform_keys(&:to_sym)
      profiler_options[:mode] = profiler_options[:mode].to_sym if profiler_options[:mode]

      DEFAULT_OPTIONS.merge(profiler_options, {out: rundata[:filename]})
    end
  end
end
