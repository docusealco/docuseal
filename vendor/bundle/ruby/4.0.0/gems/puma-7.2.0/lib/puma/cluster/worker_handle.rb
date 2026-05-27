# frozen_string_literal: true

module Puma
  class Cluster < Runner
    #—————————————————————— DO NOT USE — this class is for internal use only ———

    # This class represents a worker process from the perspective of the puma
    # master process. It contains information about the process and its health
    # and it exposes methods to control the process via IPC. It does not
    # include the actual logic executed by the worker process itself. For that,
    # see Puma::Cluster::Worker.
    class WorkerHandle # :nodoc:
      # array of stat 'max' keys
      WORKER_MAX_KEYS = [:backlog_max, :reactor_max]

      def initialize(idx, pid, phase, options)
        @index = idx
        @pid = pid
        @phase = phase
        @stage = :started
        @signal = "TERM"
        @options = options
        @first_term_sent = nil
        @started_at = Time.now
        @last_checkin = Time.now
        @last_status = {}
        @term = false
        @worker_max = Array.new WORKER_MAX_KEYS.length, 0
      end

      attr_reader :index, :pid, :phase, :signal, :last_checkin, :last_status, :started_at, :process_status

      # @version 5.0.0
      attr_writer :pid, :phase, :process_status

      def booted?
        @stage == :booted
      end

      def uptime
        Time.now - started_at
      end

      def boot!
        @last_checkin = Time.now
        @stage = :booted
      end

      def term!
        @term = true
      end

      def term?
        @term
      end

      def ping!(status)
        hsh = {}
        k, v = nil, nil
        status.tr('}{"', '').strip.split(", ") do |kv|
          cntr = 0
          kv.split(':') do |t|
            if cntr == 0
              k = t
              cntr = 1
            else
              v = t
            end
          end
          hsh[k.to_sym] = v.to_i
        end

        # check stat max values, we can't signal workers to reset the max values,
        # so we do so here
        WORKER_MAX_KEYS.each_with_index do |key, idx|
          next unless hsh[key]

          if hsh[key] < @worker_max[idx]
            hsh[key] = @worker_max[idx]
          else
            @worker_max[idx] = hsh[key]
          end
        end
        @last_checkin = Time.now
        @last_status = hsh
      end

      # Resets max values to zero.  Called whenever `Cluster#stats` is called
      def reset_max
        WORKER_MAX_KEYS.length.times { |idx| @worker_max[idx] = 0 }
      end

      # @see Puma::Cluster#check_workers
      # @version 5.0.0
      def ping_timeout
        @last_checkin +
          (booted? ?
            @options[:worker_timeout] :
            @options[:worker_boot_timeout]
          )
      end

      def term
        begin
          if @first_term_sent && (Time.now - @first_term_sent) > @options[:worker_shutdown_timeout]
            @signal = "KILL"
          else
            @term ||= true
            @first_term_sent ||= Time.now
          end
          Process.kill @signal, @pid if @pid
        rescue Errno::ESRCH
        end
      end

      def kill
        @signal = 'KILL'
        term
      end

      def hup
        Process.kill "HUP", @pid
      rescue Errno::ESRCH
      end
    end
  end
end
