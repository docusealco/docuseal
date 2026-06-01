# Deployment engineering for Puma

Puma expects to be run in a deployed environment eventually. You can use it as
your development server, but most people use it in their production deployments.

To that end, this document serves as a foundation of wisdom regarding deploying
Puma to production while increasing happiness and decreasing downtime.

## Specifying Puma

Most people will specify Puma by including `gem "puma"` in a Gemfile, so we'll
assume this is how you're using Puma.

## Single vs. Cluster mode

Initially, Puma was conceived as a thread-only web server, but support for
processes was added in version 2.

In general, use single mode only if:

* You are using JRuby, TruffleRuby or another fully-multithreaded implementation of Ruby
* You are using MRI but in an environment where only 1 CPU core is available.

Otherwise, you'll want to use cluster mode to utilize all available CPU resources.

To run `puma` in single mode (i.e., as a development environment), set the
number of workers to 0; anything higher will run in cluster mode.

## Cluster Mode Tips

For the purposes of Puma provisioning, "CPU cores" means:

1. On ARM, the number of physical cores.
2. On x86, the number of logical cores, hyperthreads, or vCPUs (these words all mean the same thing).

Set your config with the following process:

* Use cluster mode and set `workers :auto` (requires the `concurrent-ruby` gem) to match the number of CPU cores on the machine (minimum 2, otherwise use single mode!). If you can't add the gem, set the worker count manually to the available CPU cores.
* Set the number of threads to desired concurrent requests/number of workers.
  Puma defaults to 5, and that's a decent number.

For most deployments, adding `concurrent-ruby` and using `workers :auto` is the right starting point.

See [`workers :auto` gotchas](../lib/puma/dsl.rb).

## Worker utilization

**How do you know if you've got enough (or too many workers)?**

A good question. Due to MRI's GIL, only one thread can be executing Ruby code at
a time. But since so many apps are waiting on IO from DBs, etc., they can
utilize threads to use the process more efficiently.

Generally, you never want processes that are pegged all the time. That can mean
there is more work to do than the process can get through, and requests will end up with additional latency. On the other hand, if
you have processes that sit around doing nothing, then you're wasting resources and money.

In general, you are making a tradeoff between:

1. CPU and memory utilization.
2. Time spent queueing for a Puma worker to `accept` requests and additional latency caused by CPU contention.

If latency is important to you, you will have to accept lower utilization, and vice versa.

## Container/VPS sizing

You will have to make a decision about how "big" to make each pod/VPS/server/dyno.

**TL:DR;**: 80% of Puma apps will end up deploying "pods" of 4 workers, 5 threads each, 4 vCPU and 8GB of RAM.

For the rest of this discussion, we'll adopt the Kubernetes term of "pods".

Should you run 2 pods with 50 workers each? 25 pods, each with 4 workers? 100 pods, with each Puma running in single mode? Each scenario represents the same total amount of capacity (100 Puma processes that can respond to requests), but there are tradeoffs to make:

* **Increasing worker counts decreases latency, but means you scale in bigger "chunks"**. Worker counts should be somewhere between 4 and 32 in most cases. You want more than 4 in order to minimize time spent in request queueing for a free Puma worker, but probably less than ~32 because otherwise autoscaling is working in too large of an increment or they probably won't fit very well into your nodes. In any queueing system, queue time is proportional to 1/n, where n is the number of things pulling from the queue. Each pod will have its own request queue (i.e., the socket backlog). If you have 4 pods with 1 worker each (4 request queues), wait times are, proportionally, about 4 times higher than if you had 1 pod with 4 workers (1 request queue).
* **Increasing thread counts will increase throughput, but also latency and memory use** Unless you have a very I/O-heavy application (50%+ time spent waiting on IO), use the default thread count (5 for MRI). Using higher numbers of threads with low I/O wait (<50% of wall clock time) will lead to additional request latency and additional memory usage.
* **Increasing worker counts decreases memory per worker on average**. More processes per pod reduces memory usage per process, because of copy-on-write memory and because the cost of the single master process is "amortized" over more child processes.
* **Low worker counts (<4) have exceptionally poor throughput**. Don't run less than 4 processes per pod if you can. Low numbers of processes per pod will lead to high request queueing (see discussion above), which means you will have to run more pods and resources.
* **CPU-core-to-worker ratios should be around 1**. If running Puma with `threads > 1`, allocate 1 CPU core (see definition above!) per worker. If single threaded, allocate ~0.75 cpus per worker. Most web applications spend about 25% of their time in I/O - but when you're running multi-threaded, your Puma process will have higher CPU usage and should be able to fully saturate a CPU core. Using `workers :auto` will size workers to this guidance on most platforms.
* **Don't set memory limits unless necessary**. Most Puma processes will use about ~512MB-1GB per worker, and about 1GB for the master process. However, you probably shouldn't bother with setting memory limits lower than around 2GB per process, because most places you are deploying will have 2GB of RAM per CPU. A sensible memory limit for a Puma configuration of 4 child workers might be something like 8 GB (1 GB for the master, 7GB for the 4 children).

**Measuring utilization and queue time**

Using a timestamp header from an upstream proxy server (e.g., `nginx` or
`haproxy`) makes it possible to indicate how long requests have been waiting for
a Puma thread to become available.

* Have your upstream proxy set a header with the time it received the request:
    * nginx: `proxy_set_header X-Request-Start "${msec}";`
    * haproxy >= 1.9: `http-request set-header X-Request-Start
      t=%[date()]%[date_us()]`
    * haproxy < 1.9: `http-request set-header X-Request-Start t=%[date()]`
* In your Rack middleware, determine the amount of time elapsed since
  `X-Request-Start`.
* To improve accuracy, you will want to subtract time spent waiting for slow
  clients:
    * `env['puma.request_body_wait']` contains the number of milliseconds Puma
      spent waiting for the client to send the request body.
    * haproxy: `%Th` (TLS handshake time) and `%Ti` (idle time before request)
      can also be added as headers.

## Should I daemonize?

The Puma 5.0 release removed daemonization. For older versions and alternatives,
continue reading.

I prefer not to daemonize my servers and use something like `runit` or `systemd`
to monitor them as child processes. This gives them fast response to crashes and
makes it easy to figure out what is going on. Additionally, unlike `unicorn`,
Puma does not require daemonization to do zero-downtime restarts.

I see people using daemonization because they start puma directly via Capistrano
task and thus want it to live on past the `cap deploy`. To these people, I say:
You need to be using a process monitor. Nothing is making sure Puma stays up in
this scenario! You're just waiting for something weird to happen, Puma to die,
and to get paged at 3 AM. Do yourself a favor, at least the process monitoring
your OS comes with, be it `sysvinit` or `systemd`. Or branch out and use `runit`
or hell, even `monit`.

## Restarting

You probably will want to deploy some new code at some point, and you'd like
Puma to start running that new code. There are a few options for restarting
Puma, described separately in our [restart documentation](restart.md).

## Migrating from Unicorn

* If you're migrating from unicorn though, here are some settings to start with:
  * Set workers to half the number of unicorn workers you're using
  * Set threads to 2
  * Enjoy 50% memory savings
* As you grow more confident in the thread-safety of your app, you can tune the
  workers down and the threads up.

## Ubuntu / Systemd (Systemctl) Installation

See [systemd.md](systemd.md)
