# frozen_string_literal: true

require "sidekiq/paginator"
require "sidekiq/web/helpers"

module Sidekiq
  class Web
    class Application
      extend Router
      include Router

      REDIS_KEYS = %w[redis_version uptime_in_days connected_clients used_memory_human used_memory_peak_human]

      CSP_HEADER_TEMPLATE = [
        "default-src 'self' https: http:",
        "child-src 'self'",
        "connect-src 'self' https: http: wss: ws:",
        "font-src 'none'",
        "frame-src 'self'",
        "img-src 'self' https: http: data:",
        "manifest-src 'self'",
        "media-src 'self'",
        "object-src 'none'",
        "script-src 'self' 'nonce-!placeholder!'",
        "style-src 'self' 'nonce-!placeholder!'",
        "worker-src 'self'",
        "base-uri 'self'"
      ].join("; ").freeze

      METRICS_PERIODS = {
        "1h" => {minutes: 60},
        "2h" => {minutes: 120},
        "4h" => {minutes: 240},
        "8h" => {minutes: 480},
        "24h" => {hours: 24},
        "48h" => {hours: 48},
        "72h" => {hours: 72}
      }

      def initialize(inst)
        @app = inst
      end

      head "/" do
        # HEAD / is the cheapest heartbeat possible,
        # it hits Redis to ensure connectivity
        _ = Sidekiq.redis { |c| c.llen("queue:default") }
        ""
      end

      get "/" do
        @redis_info = redis_info.slice(*REDIS_KEYS)
        days = (url_params("days") || 30).to_i
        return halt(401) if days < 1 || days > 180

        stats_history = Sidekiq::Stats::History.new(days)
        @processed_history = stats_history.processed
        @failed_history = stats_history.failed

        erb(:dashboard)
      end

      get "/metrics" do
        x = url_params("substr")
        class_filter = (x.nil? || x == "") ? nil : Regexp.new(Regexp.escape(x), Regexp::IGNORECASE)

        q = Sidekiq::Metrics::Query.new
        @period = h(url_params("period") || "1h")
        @periods = METRICS_PERIODS
        args = @periods.fetch(@period, @periods.values.first)
        @query_result = q.top_jobs(**args.merge(class_filter: class_filter))

        header "refresh", 60 if @period == "1h"
        erb(:metrics)
      end

      get "/metrics/:name" do
        @name = route_params(:name)
        @period = h(url_params("period") || "1h")
        # Periods larger than 8 hours are not supported for histogram chart
        @period = "8h" if @period.to_i > 8
        @periods = METRICS_PERIODS.reject { |k, v| k.to_i > 8 }
        args = @periods.fetch(@period, @periods.values.first)
        q = Sidekiq::Metrics::Query.new
        @query_result = q.for_job(@name, **args)

        header "refresh", 60 if @period == "1h"
        erb(:metrics_for_job)
      end

      get "/busy" do
        @count = (url_params("count") || 100).to_i
        (@current_page, @total_size, @workset) = page_items(workset, url_params("page"), @count)

        erb(:busy)
      end

      post "/busy" do
        if url_params("identity")
          pro = Sidekiq::ProcessSet[url_params("identity")]

          pro&.quiet! if url_params("quiet")
          pro&.stop! if url_params("stop")
        else
          processes.each do |pro|
            next if pro.embedded?

            pro.quiet! if url_params("quiet")
            pro.stop! if url_params("stop")
          end
        end

        redirect "#{root_path}busy"
      end

      get "/queues" do
        @queues = Sidekiq::Queue.all

        erb(:queues)
      end

      QUEUE_NAME = /\A[a-z_:.\-0-9]+\z/i

      get "/queues/:name" do
        @name = route_params(:name)

        halt(404) if !@name || @name !~ QUEUE_NAME

        @count = (url_params("count") || 25).to_i
        @queue = Sidekiq::Queue.new(@name)
        (@current_page, @total_size, @jobs) = page("queue:#{@name}", url_params("page"), @count, reverse: url_params("direction") == "asc")
        @jobs = @jobs.map { |msg| Sidekiq::JobRecord.new(msg, @name) }

        erb(:queue)
      end

      post "/queues/:name" do
        queue = Sidekiq::Queue.new(route_params(:name))

        if Sidekiq.pro? && url_params("pause")
          queue.pause!
        elsif Sidekiq.pro? && url_params("unpause")
          queue.unpause!
        else
          queue.clear
        end

        redirect "#{root_path}queues"
      end

      post "/queues/:name/delete" do
        name = route_params(:name)
        Sidekiq::JobRecord.new(url_params("key_val"), name).delete

        redirect_with_query("#{root_path}queues/#{CGI.escape(name)}")
      end

      get "/morgue" do
        x = url_params("substr")

        if x && x != ""
          @dead = search(Sidekiq::DeadSet.new, x)
        else
          @count = (url_params("count") || 25).to_i
          (@current_page, @total_size, @dead) = page("dead", url_params("page"), @count, reverse: true)
          @dead = @dead.map { |msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }
        end

        erb(:morgue)
      end

      get "/morgue/:key" do
        key = route_params(:key)
        halt(404) unless key

        @dead = Sidekiq::DeadSet.new.fetch(*parse_key(key)).first

        if @dead.nil?
          redirect "#{root_path}morgue"
        else
          erb(:dead)
        end
      end

      post "/morgue" do
        redirect(request.path) unless url_params("key")

        url_params("key").each do |key|
          job = Sidekiq::DeadSet.new.fetch(*parse_key(key)).first
          retry_or_delete_or_kill job, request.params if job
        end

        redirect_with_query("#{root_path}morgue")
      end

      post "/morgue/all/delete" do
        Sidekiq::DeadSet.new.clear

        redirect "#{root_path}morgue"
      end

      post "/morgue/all/retry" do
        Sidekiq::DeadSet.new.retry_all

        redirect "#{root_path}morgue"
      end

      post "/morgue/:key" do
        key = route_params(:key)
        halt(404) unless key

        job = Sidekiq::DeadSet.new.fetch(*parse_key(key)).first
        retry_or_delete_or_kill job, request.params if job

        redirect_with_query("#{root_path}morgue")
      end

      get "/retries" do
        x = url_params("substr")

        if x && x != ""
          @retries = search(Sidekiq::RetrySet.new, x)
        else
          @count = (url_params("count") || 25).to_i
          (@current_page, @total_size, @retries) = page("retry", url_params("page"), @count)
          @retries = @retries.map { |msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }
        end

        erb(:retries)
      end

      get "/retries/:key" do
        @retry = Sidekiq::RetrySet.new.fetch(*parse_key(route_params(:key))).first

        if @retry.nil?
          redirect "#{root_path}retries"
        else
          erb(:retry)
        end
      end

      post "/retries" do
        redirect(request.path) unless url_params("key")

        url_params("key").each do |key|
          job = Sidekiq::RetrySet.new.fetch(*parse_key(key)).first
          retry_or_delete_or_kill job, request.params if job
        end

        redirect_with_query("#{root_path}retries")
      end

      post "/retries/all/delete" do
        Sidekiq::RetrySet.new.clear
        redirect "#{root_path}retries"
      end

      post "/retries/all/retry" do
        Sidekiq::RetrySet.new.retry_all
        redirect "#{root_path}retries"
      end

      post "/retries/all/kill" do
        Sidekiq::RetrySet.new.kill_all
        redirect "#{root_path}retries"
      end

      post "/retries/:key" do
        job = Sidekiq::RetrySet.new.fetch(*parse_key(route_params(:key))).first

        retry_or_delete_or_kill job, request.params if job

        redirect_with_query("#{root_path}retries")
      end

      get "/scheduled" do
        x = url_params("substr")

        if x && x != ""
          @scheduled = search(Sidekiq::ScheduledSet.new, x)
        else
          @count = (url_params("count") || 25).to_i
          (@current_page, @total_size, @scheduled) = page("schedule", url_params("page"), @count)
          @scheduled = @scheduled.map { |msg, score| Sidekiq::SortedEntry.new(nil, score, msg) }
        end

        erb(:scheduled)
      end

      get "/scheduled/:key" do
        @job = Sidekiq::ScheduledSet.new.fetch(*parse_key(route_params(:key))).first

        if @job.nil?
          redirect "#{root_path}scheduled"
        else
          erb(:scheduled_job_info)
        end
      end

      post "/scheduled" do
        redirect(request.path) unless url_params("key")

        url_params("key").each do |key|
          job = Sidekiq::ScheduledSet.new.fetch(*parse_key(key)).first
          delete_or_add_queue job, request.params if job
        end

        redirect_with_query("#{root_path}scheduled")
      end

      post "/scheduled/:key" do
        key = route_params(:key)
        halt(404) unless key

        job = Sidekiq::ScheduledSet.new.fetch(*parse_key(key)).first
        delete_or_add_queue job, request.params if job

        redirect_with_query("#{root_path}scheduled")
      end

      post "/scheduled/all/delete" do
        Sidekiq::ScheduledSet.new.clear
        redirect "#{root_path}scheduled"
      end

      post "/scheduled/all/add_to_queue" do
        Sidekiq::ScheduledSet.new.each(&:add_to_queue)
        redirect "#{root_path}scheduled"
      end

      get "/dashboard/stats" do
        redirect "#{root_path}stats"
      end

      get "/stats" do
        sidekiq_stats = Sidekiq::Stats.new
        redis_stats = redis_info.slice(*REDIS_KEYS)
        redis_stats["store_name"] = store_name
        redis_stats["store_version"] = store_version
        json(
          sidekiq: {
            processed: sidekiq_stats.processed,
            failed: sidekiq_stats.failed,
            busy: sidekiq_stats.workers_size,
            processes: sidekiq_stats.processes_size,
            enqueued: sidekiq_stats.enqueued,
            scheduled: sidekiq_stats.scheduled_size,
            retries: sidekiq_stats.retry_size,
            dead: sidekiq_stats.dead_size,
            default_latency: sidekiq_stats.default_queue_latency
          },
          redis: redis_stats,
          server_utc_time: server_utc_time
        )
      end

      get "/stats/queues" do
        json Sidekiq::Stats.new.queues
      end

      get "/profiles" do
        erb(:profiles)
      end

      get "/profiles/:key" do
        store = config[:profile_store_url]
        return redirect_to "#{root_path}profiles" unless store

        key = route_params(:key)
        sid = Sidekiq.redis { |c| c.hget(key, "sid") }

        unless sid
          require "net/http"
          data = Sidekiq.redis { |c| c.hget(key, "data") }

          store_uri = URI(store)
          http = Net::HTTP.new(store_uri.host, store_uri.port)
          http.use_ssl = store_uri.scheme == "https"
          request = Net::HTTP::Post.new(store_uri.request_uri)
          request.body = data
          request["Accept"] = "application/vnd.firefox-profiler+json;version=1.0"
          request["User-Agent"] = "Sidekiq #{Sidekiq::VERSION} job profiler"

          resp = http.request(request)
          # https://raw.githubusercontent.com/firefox-devtools/profiler-server/master/tools/decode_jwt_payload.py
          rawjson = resp.body.split(".")[1].unpack1("m")
          sid = Sidekiq.load_json(rawjson)["profileToken"]
          Sidekiq.redis { |c| c.hset(key, "sid", sid) }
        end
        url = config[:profile_view_url] % sid
        redirect_to url
      end

      get "/profiles/:key/data" do
        key = route_params(:key)
        data = Sidekiq.redis { |c| c.hget(key, "data") }

        [200, {
          "content-type" => "application/json",
          "content-encoding" => "gzip",
          # allow Firefox Profiler's XHR to fetch this profile data
          "access-control-allow-origin" => "*"
        }, [data]]
      end

      post "/change_locale" do
        locale = url_params("locale")

        match = available_locales.find { |available|
          locale == available
        }

        session[:locale] = match if match

        reload_page
      end

      def redis(&)
        Thread.current[:sidekiq_redis_pool].with(&)
      end

      def call(env)
        action = match(env)
        return [404, {"content-type" => "text/plain", "x-cascade" => "pass"}, ["Not Found"]] unless action

        headers = {
          "content-type" => "text/html",
          "cache-control" => "private, no-store",
          "content-language" => action.locale,
          "content-security-policy" => process_csp(env, CSP_HEADER_TEMPLATE),
          "x-content-type-options" => "nosniff"
        }
        env["response_headers"] = headers
        resp = catch(:halt) do
          Thread.current[:sidekiq_redis_pool] = env[:redis_pool]
          action.instance_exec env, &action.block
        ensure
          Thread.current[:sidekiq_redis_pool] = nil
        end

        case resp
        when Array
          # redirects go here
          resp
        else
          # rendered content goes here
          # we'll let Rack calculate Content-Length for us.
          [200, env["response_headers"], [resp]]
        end
      end

      def process_csp(env, input)
        input.gsub("!placeholder!", env[:csp_nonce])
      end

      # Used by extensions to add helper methods accessible to
      # any defined endpoints in Application. Careful with generic
      # method naming as there's no namespacing so collisions are
      # possible.
      def self.helpers(mod)
        Sidekiq::Web::Action.send(:include, mod)
      end
      helpers WebHelpers
      helpers Paginator
    end
  end
end
