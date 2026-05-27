# frozen_string_literal: true

require "etc"
require "rbconfig"
require "io/wait" unless IO.method_defined?(:wait_readable)

module Bootsnap
  class CLI
    class WorkerPool
      class << self
        def create(size:, jobs:)
          size ||= default_size
          if size > 0 && Process.respond_to?(:fork)
            new(size: size, jobs: jobs)
          else
            Inline.new(jobs: jobs)
          end
        end

        def default_size
          nprocessors = Etc.nprocessors
          size = [nprocessors, cpu_quota&.to_i || nprocessors].min
          case size
          when 0, 1
            0
          else
            if fork_defunct?
              $stderr.puts "warning: faulty fork(2) detected, probably in cross platform docker builds. " \
                           "Disabling parallel compilation."
              0
            else
              size
            end
          end
        end

        def cpu_quota
          if RbConfig::CONFIG["target_os"].include?("linux")
            if File.exist?("/sys/fs/cgroup/cpu.max")
              # cgroups v2: https://docs.kernel.org/admin-guide/cgroup-v2.html#cpu-interface-files
              cpu_max = File.read("/sys/fs/cgroup/cpu.max")
              return nil if cpu_max.start_with?("max ") # no limit

              max, period = cpu_max.split.map(&:to_f)
              max / period
            elsif File.exist?("/sys/fs/cgroup/cpu,cpuacct/cpu.cfs_quota_us")
              # cgroups v1: https://kernel.googlesource.com/pub/scm/linux/kernel/git/glommer/memcg/+/cpu_stat/Documentation/cgroups/cpu.txt
              max = File.read("/sys/fs/cgroup/cpu,cpuacct/cpu.cfs_quota_us").to_i
              # If the cpu.cfs_quota_us is -1, cgroup does not adhere to any CPU time restrictions
              # https://docs.kernel.org/scheduler/sched-bwc.html#management
              return nil if max <= 0

              period = File.read("/sys/fs/cgroup/cpu,cpuacct/cpu.cfs_period_us").to_f
              max / period
            end
          end
        end

        def fork_defunct?
          return true unless ::Process.respond_to?(:fork)

          # Ref: https://github.com/rails/bootsnap/issues/495
          # The second forked process will hang on some QEMU environments
          r, w = IO.pipe
          pids = 2.times.map do
            ::Process.fork do
              exit!(true)
            end
          end
          w.close
          r.wait_readable(1) # Wait at most 1s

          defunct = false

          pids.each do |pid|
            _pid, status = ::Process.wait2(pid, ::Process::WNOHANG)
            if status.nil? # Didn't exit in 1s
              defunct = true
              Process.kill(:KILL, pid)
              ::Process.wait2(pid)
            end
          end

          defunct
        end
      end

      class Inline
        def initialize(jobs: {})
          @jobs = jobs
        end

        def push(job, *args)
          @jobs.fetch(job).call(*args)
          nil
        end

        def spawn
          # noop
        end

        def shutdown
          # noop
        end
      end

      class Worker
        attr_reader :to_io, :pid

        def initialize(jobs)
          @jobs = jobs
          @pipe_out, @to_io = IO.pipe(binmode: true)
          # Set the writer encoding to binary since IO.pipe only sets it for the reader.
          # https://github.com/rails/rails/issues/16514#issuecomment-52313290
          @to_io.set_encoding(Encoding::BINARY)

          @pid = nil
        end

        def write(message, block: true)
          payload = Marshal.dump(message)
          if block
            to_io.write(payload)
            true
          else
            to_io.write_nonblock(payload, exception: false) != :wait_writable
          end
        end

        def close
          to_io.close
        end

        def work_loop
          loop do
            job, *args = Marshal.load(@pipe_out)
            return if job == :exit

            @jobs.fetch(job).call(*args)
          end
        rescue IOError
          nil
        end

        def spawn
          @pid = Process.fork do
            to_io.close
            work_loop
            exit!(0)
          end
          @pipe_out.close
          true
        end
      end

      def initialize(size:, jobs: {})
        @size = size
        @jobs = jobs
        @queue = Queue.new
        @pids = []
      end

      def spawn
        @workers = @size.times.map { Worker.new(@jobs) }
        @workers.each(&:spawn)
        @dispatcher_thread = Thread.new { dispatch_loop }
        @dispatcher_thread.abort_on_exception = true
        true
      end

      def dispatch_loop
        loop do
          case job = @queue.pop
          when nil
            @workers.each do |worker|
              worker.write([:exit])
              worker.close
            end
            return true
          else
            unless @workers.sample.write(job, block: false)
              free_worker.write(job)
            end
          end
        end
      end

      def free_worker
        IO.select(nil, @workers)[1].sample
      end

      def push(*args)
        @queue.push(args)
        nil
      end

      def shutdown
        @queue.close
        @dispatcher_thread.join
        @workers.each do |worker|
          _pid, status = Process.wait2(worker.pid)
          return status.exitstatus unless status.success?
        end
        nil
      end
    end
  end
end
