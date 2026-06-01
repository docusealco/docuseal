Sidekiq
==============

[![Gem Version](https://badge.fury.io/rb/sidekiq.svg)](https://rubygems.org/gems/sidekiq)
![Build](https://github.com/sidekiq/sidekiq/workflows/CI/badge.svg)

Simple, efficient background jobs for Ruby.

Sidekiq uses threads to handle many jobs at the same time in the
same process. Sidekiq can be used by any Ruby application.


Requirements
-----------------

- Redis: Redis 7.0+, Valkey 7.2+ or Dragonfly 1.27+
- Ruby: MRI 3.2+ or JRuby 9.4+.

Sidekiq 8.0 supports Rails and Active Job 7.0+.

Sidekiq supports [Valkey](https://valkey.io) and [Dragonfly](https://www.dragonflydb.io) as Redis alternatives.
Redis 7.2.4 is considered to be the canonical implementation.
Incompatibilities with that version are considered bugs.

Installation
-----------------

    bundle add sidekiq


Getting Started
-----------------

See the [Getting Started wiki page](https://github.com/sidekiq/sidekiq/wiki/Getting-Started) and follow the simple setup process.
You can watch [this YouTube playlist](https://www.youtube.com/playlist?list=PLjeHh2LSCFrWGT5uVjUuFKAcrcj5kSai1) to learn all about
Sidekiq and see its features in action.  Here's the Web UI:

![Web UI](https://github.com/sidekiq/sidekiq/raw/main/examples/web-ui.png)

Performance
---------------

The benchmark in `bin/sidekiqload` creates 500,000 no-op jobs and drains them as fast as possible, assuming a fixed Redis network latency of 1ms.
This requires a lot of Redis network I/O and JSON parsing.
This benchmark is IO-bound so we increase the concurrency to 25.
If your application is sending lots of emails or performing other network-intensive work, you could see a similar benefit but be careful not to saturate the CPU.
Real world applications will rarely if ever need to use concurrency greater than 10.

Version | Time to process 500k jobs | Throughput (jobs/sec) | Ruby | Concurrency | Job Type
-----------------|------|---------|---------|------------------------|---
Sidekiq 7.0.3 | 21.3 sec| 23,500 | 3.2.0+yjit | 30 | Sidekiq::Job
Sidekiq 7.0.3 | 33.8 sec| 14,700 | 3.2.0+yjit | 30 | ActiveJob 7.0.4
Sidekiq 7.0.3 | 23.5 sec| 21,300 | 3.2.0 | 30 | Sidekiq::Job
Sidekiq 7.0.3 | 46.5 sec| 10,700 | 3.2.0 | 30 | ActiveJob 7.0.4
Sidekiq 7.0.3 | 23.0 sec| 21,700 | 2.7.5 | 30 | Sidekiq::Job
Sidekiq 7.0.3 | 46.5 sec| 10,850 | 2.7.5 | 30 | ActiveJob 7.0.4

Most of Sidekiq's overhead is Redis network I/O.
ActiveJob adds a notable amount of CPU overhead due to argument deserialization and callbacks.
Concurrency of 30 was determined experimentally to maximize one CPU without saturating it.

Want to Upgrade?
-------------------

Use `bundle up sidekiq` to upgrade Sidekiq and all its dependencies.
Upgrade notes between each major version can be found in the `docs/` directory.

I also sell [Sidekiq Pro](https://billing.contribsys.com/spro/) and [Sidekiq Enterprise](https://billing.contribsys.com/sent/new.cgi), extensions to Sidekiq which provide more
features, a commercial-friendly license and allow you to support high
quality open source development all at the same time.  Please see the
[Sidekiq](https://sidekiq.org/) homepage for more detail.


Problems?
-----------------

**Do not directly email any Sidekiq committers with questions or problems.**
A community is best served when discussions are held in public.

If you have a problem, please review the [FAQ](https://github.com/sidekiq/sidekiq/wiki/FAQ) and [Troubleshooting](https://github.com/sidekiq/sidekiq/wiki/Problems-and-Troubleshooting) wiki pages.
Searching the [issues](https://github.com/sidekiq/sidekiq/issues) for your problem is also a good idea.

Sidekiq Pro and Sidekiq Enterprise customers get private email support.
You can purchase at https://sidekiq.org; email support@contribsys.com for help.

Useful resources:

* Product documentation is in the [wiki](https://github.com/sidekiq/sidekiq/wiki).
* Occasional announcements are made to the [@sidekiq](https://ruby.social/@sidekiq) Mastodon account.
* The [Sidekiq tag](https://stackoverflow.com/questions/tagged/sidekiq) on Stack Overflow has lots of useful Q &amp; A.

Every Thursday morning is Sidekiq Office Hour: I video chat and answer questions.
See the [Sidekiq support page](https://sidekiq.org/support/) for details.

Contributing
-----------------

See [the contributing guidelines](https://github.com/sidekiq/sidekiq/blob/main/.github/contributing.md).

### ERB Linting with HERB

This project uses [HERB](https://herb-tools.dev/) for ERB file linting and formatting. All ERB files have been renamed to use the `.html.erb` extension for better tooling support.

**Local Development:**
```bash
# Run HERB linting
bundle exec rake lint:herb
# or
bin/lint-herb
```

**CI Integration:**
HERB linting is automatically run in CI to ensure all ERB files are properly formatted and free of parse errors.

License
-----------------

See [LICENSE.txt](https://github.com/sidekiq/sidekiq/blob/main/LICENSE.txt) for licensing details.
The license for Sidekiq Pro and Sidekiq Enterprise can be found in [COMM-LICENSE.txt](https://github.com/sidekiq/sidekiq/blob/main/COMM-LICENSE.txt).

Author
-----------------

Mike Perham, [mastodon](https://ruby.social/@getajobmike), [https://www.mikeperham.com](https://www.mikeperham.com) / [https://www.contribsys.com](https://www.contribsys.com)
