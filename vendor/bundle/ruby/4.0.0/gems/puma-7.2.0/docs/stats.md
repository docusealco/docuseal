## Accessing stats

Stats can be accessed in two ways:

### control server

`$ pumactl stats` or `GET /stats`

[Read more about `pumactl` and the control server in the README.](https://github.com/puma/puma#controlstatus-server).

### Puma.stats

`Puma.stats` produces a JSON string. `Puma.stats_hash` produces a ruby hash.

#### in single mode

Invoke `Puma.stats` anywhere in runtime, e.g. in a rails initializer:

```ruby
# config/initializers/puma_stats.rb

Thread.new do
  loop do
    sleep 30
    puts Puma.stats
  end
end
```

#### in cluster mode

Invoke `Puma.stats` from the master process

```ruby
# config/puma.rb

before_fork do
  Thread.new do
    loop do
      puts Puma.stats
      sleep 30
    end
  end
end
```


## Explanation of stats

`Puma.stats` returns different information and a different structure depending on if Puma is in single vs. cluster mode. There is one top-level attribute that is common to both modes:

* started_at: when Puma was started

### single mode and individual workers in cluster mode

When Puma runs in single mode, these stats are available at the top level. When Puma runs in cluster mode, these stats are available within the `worker_status` array in a hash labeled `last_status`, in an array of hashes where one hash represents each worker.

* backlog: requests that are waiting for an available thread to be available. if this is frequently above 0, you need more capacity.
* running: how many threads are spawned. A spawned thread may be busy processing a request or waiting for a new request. If `min_threads` and `max_threads` are set to the same number,
  this will be a never-changing number (other than rare cases when a thread dies, etc).
* busy_threads: `running` - `how many threads are waiting to receive work` + `how many requests are waiting for a thread to pick them up`.
  this is a "wholistic" stat reflecting the overall current state of work to be done and the capacity to do it.
* pool_capacity: `how many threads are waiting to receive work` + `max_threads` - `running`. In a typical configuration where `min_threads`
  and `max_threads` are configured to the same number, this is simply `how many threads are waiting to receive work`. This number exists only as a stat
  and is not used for any internal decisions, unlike `busy_threads`, which is usually a more useful stat.
* max_threads: the maximum number of threads Puma is configured to spool per worker
* requests_count: the number of requests this worker has served since starting
* reactor_max: the maximum observed number of requests held in Puma's "reactor" which is used for asyncronously buffering request bodies. This stat is reset on every call, so it's the maximum value observed since the last stat call.
* backlog_max: the maximum number of requests that have been fully buffered by the reactor and placed in a ready queue, but have not yet been picked up by a server thread. This stat is reset on every call, so it's the maximum value observed since the last stat call.

### cluster mode

* phase: which phase of restart the process is in, during [phased restart](https://github.com/puma/puma/blob/main/docs/restart.md)
* workers: ??
* booted_workers: how many workers currently running?
* old_workers: ??
* worker_status: array of hashes of info for each worker (see below)

### worker status

* started_at: when the worker started
* pid: the process id of the worker process
* index: each worker gets a number. if Puma is configured to have 3 workers, then this will be 0, 1, or 2
* booted: if it's done booting [?]
* last_checkin: Last time the worker responded to the master process' heartbeat check.
* last_status: a hash of info about the worker's state handling requests. See the explanation for this in "single mode and individual workers in cluster mode" section above.


## Examples

Here are two example stats hashes produced by `Puma.stats`:

### single

```json
{
  "started_at": "2021-01-14T07:12:35Z",
  "backlog": 0,
  "running": 5,
  "pool_capacity": 5,
  "max_threads": 5,
  "requests_count": 3
}
```

### cluster

```json
{
  "started_at": "2021-01-14T07:09:17Z",
  "workers": 2,
  "phase": 0,
  "booted_workers": 2,
  "old_workers": 0,
  "worker_status": [
    {
      "started_at": "2021-01-14T07:09:24Z",
      "pid": 64136,
      "index": 0,
      "phase": 0,
      "booted": true,
      "last_checkin": "2021-01-14T07:11:09Z",
      "last_status": {
        "backlog": 0,
        "running": 5,
        "pool_capacity": 5,
        "max_threads": 5,
        "requests_count": 2
      }
    },
    {
      "started_at": "2021-01-14T07:09:24Z",
      "pid": 64137,
      "index": 1,
      "phase": 0,
      "booted": true,
      "last_checkin": "2021-01-14T07:11:09Z",
      "last_status": {
        "backlog": 0,
        "running": 5,
        "pool_capacity": 5,
        "max_threads": 5,
        "requests_count": 1
      }
    }
  ]
}
```
