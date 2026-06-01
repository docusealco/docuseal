# frozen_string_literal: true

module Puma
  # Calculate a delay value for sleeping when running in clustered mode
  #
  # The main reason this is a class is so it can be unit tested independently.
  # This makes modification easier in the future if we can encode properties of the
  # delay into a test instead of relying on end-to-end testing only.
  #
  # This is an imprecise mechanism to address specific goals:
  #
  # - Evenly distribute requests across all workers at start
  # - Evenly distribute CPU resources across all workers
  #
  # ## Goal: Distribute requests across workers at start
  #
  # There was a perf bug in Puma where one worker would wake up slightly before the rest and accept
  # all the requests on the socket even though it didn't have enough resources to process all of them.
  # This was originally fixed by never calling accept when a worker had more requests than threads
  # already https://github.com/puma/puma/pull/3678/files/2736ebddb3fc8528e5150b5913fba251c37a8bf7#diff-a95f46e7ce116caddc9b9a9aa81004246d5210d5da5f4df90a818c780630166bL251-L291
  #
  # With the introduction of true keepalive support, there are two ways a request can come in:
  # - A new request from a new client comes into the socket and it must be "accept"-ed
  # - A keepalive request is served and the connection is retained. Another request is then accepted
  #
  # Ideally the server handles requests in the order they come in, and ideally it doesn't accept more requests than it can handle.
  # These goals are contradictory, because when the server is at maximum capacity due to keepalive connections, it could mean we
  # block all new requests, even if those came in before the new request on the older keepalive connection.
  #
  # ## Goal: Distribute CPU resources across all workers
  #
  # - This issue was opened https://github.com/puma/puma/issues/2078
  #
  # There are several entangled issues and it's not exactly clear what the root cause is, but the observable outcome
  # was that performance was better with a small sleep, and that eventually became the default.
  #
  # An attempt to describe why this works is here: https://github.com/puma/puma/issues/2078#issuecomment-3287032470.
  #
  # Summarizing: The delay is for tuning the rate at which "accept" is called on the socket.
  # Puma works by calling "accept" nonblock on the socket in a loop. When there are multiple workers
  # (processes), they will "race" to accept a request at roughly the same rate. However, if one
  # worker has all threads busy processing requests, then accepting a new request might "steal" it from
  # a less busy worker. If a worker has no work to do, it should loop as fast as possible.
  #
  # ## Solution: Distribute requests across workers at start
  #
  # For now, both goals are framed as "load balancing" across workers (processes) and achieved through
  # the same mechanism of sleeping longer to delay busier workers. Rather than the prior Puma 6.x
  # and earlier behavior of using a binary on/off sleep value, we increase it an amount proportional
  # to the load the server is under, capping the maximum delay to the scenario where all threads are busy
  # and the todo list has reached a multiplier of the maximum number of threads.
  #
  # Private: API may change unexpectedly
  class ClusterAcceptLoopDelay
    attr_reader :max_delay

    # Initialize happens once, `call` happens often. Perform global calculations here.
    def initialize(
      # Number of workers in the cluster
      workers: ,
      # Maximum delay in seconds i.e. 0.005 is 5 milliseconds
      max_delay:
    )
      @on = max_delay > 0 && workers >= 2
      @max_delay = max_delay.to_f

      # Reach maximum delay when `max_threads * overload_multiplier` is reached in the system
      @overload_multiplier = 25.0
    end

    def on?
      @on
    end

    # We want the extreme values of this delay to be known (minimum and maximum) as well as
    # a predictable curve between the two. i.e. no step functions or hard cliffs.
    #
    # Return value is always numeric. Returns 0 if there should be no delay.
    def calculate(
      # Number of threads working right now, plus number of requests in the todo list
      busy_threads_plus_todo:,
      # Maximum number of threads in the pool, note that the busy threads (alone) may go over this value at times
      # if the pool needs to be reaped. The busy thread plus todo count may go over this value by a large amount.
      max_threads:
    )
      max_value = @overload_multiplier * max_threads
      # Approaches max delay when `busy_threads_plus_todo` approaches `max_value`
      return max_delay * busy_threads_plus_todo.clamp(0, max_value) / max_value
    end
  end
end
