The [unix signal](https://en.wikipedia.org/wiki/Unix_signal) is a method of sending messages between [processes](https://en.wikipedia.org/wiki/Process_(computing)). When a signal is sent, the operating system interrupts the target process's normal flow of execution. There are standard signals that are used to stop a process, but there are also custom signals that can be used for other purposes. This document is an attempt to list all supported signals that Puma will respond to. In general, signals need only be sent to the master process of a cluster.

## Sending Signals

If you are new to signals, it can be helpful to see how they are used. When a process starts in a *nix-like operating system, it will have a [PID - or process identifier](https://en.wikipedia.org/wiki/Process_identifier) that can be used to send signals to the process. For demonstration, we will create an infinitely running process by tailing a file:

```sh
$ echo "foo" >> my.log
$ irb
> pid = Process.spawn 'tail -f my.log'
```

From here, we can see that the tail process is running by using the `ps` command:

```sh
$ ps aux | grep tail
schneems        87152   0.0  0.0  2432772    492 s032  S+   12:46PM   0:00.00 tail -f my.log
```

You can send a signal in Ruby using the [Process module](https://docs.ruby-lang.org/en/master/Process.html#method-c-kill):

```
$ irb
> puts pid
=> 87152
Process.detach(pid) # https://docs.ruby-lang.org/en/master/Process.html#method-c-detach
Process.kill("TERM", pid)
```

Now you will see via `ps` that there is no more `tail` process. Sometimes when referring to signals, the `SIG` prefix will be used. For example, `SIGTERM` is equivalent to sending `TERM` via `Process.kill`.

## Puma Signals

Puma cluster responds to these signals:

- `TTIN`: Increment the worker count by 1.
- `TTOU`: Decrement the worker count by 1.
- `TERM`: Send `TERM` to worker. The worker will attempt to finish then exit.
- `USR2`: Restart workers. This also reloads the Puma configuration file, if there is one.
- `USR1`: Restart workers in phases, a rolling restart. This will not reload the configuration file.
- `HUP`:  Reopen log files defined in `stdout_redirect` configuration parameter. If there is no `stdout_redirect` option provided, it will behave like `INT`.
- `INT`:  Equivalent of sending Ctrl-C to cluster. Puma will attempt to finish then exit.
- `CHLD`: Reap zombie child processes and wake event loop in `fork_worker` mode.
- `URG`:  Refork workers in phases from worker 0 if `fork_worker` option is enabled.
- `INFO`: Print backtraces of all Puma threads.

## Callbacks order in case of different signals

### Start application

```
puma configuration file reloaded, if there is one
* Pruning Bundler environment
puma configuration file reloaded, if there is one

before_fork
before_worker_fork
after_worker_fork

Gemfile in context

before_worker_boot

Code of the app is loaded and running
```

### Send USR2

```
before_worker_shutdown
before_restart

puma configuration file reloaded, if there is one

before_fork
before_worker_fork
after_worker_fork

Gemfile in context

before_worker_boot

Code of the app is loaded and running
```

### Send USR1

```
before_worker_shutdown
before_worker_fork
after_worker_fork

Gemfile in context

before_worker_boot

Code of the app is loaded and running
```
