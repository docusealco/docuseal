# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Shared
    class DayPeriods

      class Timestamp
        include Comparable

        attr_reader :hour, :min, :sec

        def initialize(hour, min, sec)
          @hour = hour
          @min = min
          @sec = sec
        end

        def to_f
          @to_f ||= hour * 60 * 60 + min * 60.0 + sec
        end

        def <=>(other)
          to_f <=> other.to_f
        end
      end

      class Rule
        def self.create(name, params)
          return AtRule.new(name, params) if params.include?(:at)
          FromRule.new(name, params)
        end

        attr_reader :name, :params

        def initialize(name, params)
          @name = name
          @params = params
        end
      end

      class FromRule < Rule
        def <=>(other)
          return 1 if other.params[:at]

          timespan <=> other.timespan
        end

        def timespan
          @timespan ||= if from > before
            (24 - from.to_f) + before.to_f
          else
            before.to_f - from.to_f
          end
        end

        def from
          @from ||= Timestamp.new(
            params[:from][:hour], params[:from][:min], 0
          )
        end

        def before
          @before ||= Timestamp.new(
            params[:before][:hour], params[:before][:min], 0
          )
        end

        def matches?(timestamp)
          if from > before
            timestamp >= from || timestamp < before
          else
            timestamp >= from && timestamp < before
          end
        end
      end

      class AtRule < Rule
        def <=>(other)
          -1
        end

        def timespan
          0
        end

        def at
          @at ||= Timestamp.new(
            params[:at][:hour], params[:at][:min], 0
          )
        end

        def matches?(timestamp)
          timestamp == at
        end
      end

      include Singleton

      class << self
        def instance(locale)
          instance_cache[locale] ||= new(locale)
        end

        private

        def instance_cache
          @instance_cache ||= {}
        end
      end

      attr_reader :locale, :rule_set

      def period_type_for(time)
        timestamp = Timestamp.new(time.hour, time.min, time.sec)
        rule = rules.find { |rule| rule.matches?(timestamp) }
        rule.name
      end

      def initialize(locale, rule_set = :default)
        @locale = locale
        @rule_set = rule_set
      end

      private

      def rules
        @rules ||= resource[rule_set].map do |name, params|
          Rule.create(name, params)
        end.sort
      end

      def resource
        TwitterCldr.get_locale_resource(locale, :day_periods)[locale]
      end
    end
  end
end
