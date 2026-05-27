# frozen_string_literal: true

require "logger"
require "time"

module Sidekiq
  module Context
    def self.with(hash)
      orig_context = current.dup
      current.merge!(hash)
      yield
    ensure
      Thread.current[:sidekiq_context] = orig_context
    end

    def self.current
      Thread.current[:sidekiq_context] ||= {}
    end

    def self.add(k, v)
      current[k] = v
    end
  end

  class Logger < ::Logger
    module Formatters
      class Base < ::Logger::Formatter
        COLORS = {
          "DEBUG" => "\e[1;32mDEBUG\e[0m", # green
          "INFO" => "\e[1;34mINFO \e[0m", # blue
          "WARN" => "\e[1;33mWARN \e[0m", # yellow
          "ERROR" => "\e[1;31mERROR\e[0m", # red
          "FATAL" => "\e[1;35mFATAL\e[0m" # pink
        }

        def tid
          Thread.current["sidekiq_tid"] ||= (Thread.current.object_id ^ ::Process.pid).to_s(36)
        end

        def format_context(ctxt = Sidekiq::Context.current)
          (ctxt.size == 0) ? "" : " #{ctxt.map { |k, v|
            case v
            when Array
              "#{k}=#{v.join(",")}"
            else
              "#{k}=#{v}"
            end
          }.join(" ")}"
        end
      end

      class Pretty < Base
        def call(severity, time, program_name, message)
          "#{COLORS[severity]} #{time.utc.iso8601(3)} pid=#{::Process.pid} tid=#{tid}#{format_context}: #{message}\n"
        end
      end

      class Plain < Base
        def call(severity, time, program_name, message)
          "#{severity} #{time.utc.iso8601(3)} pid=#{::Process.pid} tid=#{tid}#{format_context}: #{message}\n"
        end
      end

      class WithoutTimestamp < Pretty
        def call(severity, time, program_name, message)
          "#{COLORS[severity]} pid=#{::Process.pid} tid=#{tid}#{format_context}: #{message}\n"
        end
      end

      class JSON < Base
        def call(severity, time, program_name, message)
          hash = {
            ts: time.utc.iso8601(3),
            pid: ::Process.pid,
            tid: tid,
            lvl: severity,
            msg: message
          }
          c = Sidekiq::Context.current
          hash["ctx"] = c unless c.empty?

          Sidekiq.dump_json(hash) << "\n"
        end
      end
    end
  end
end
