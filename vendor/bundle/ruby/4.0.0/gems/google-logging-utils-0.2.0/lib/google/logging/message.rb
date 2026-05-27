# frozen_string_literal: true

# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "json"
require "google/logging/source_location"

module Google
  module Logging
    ##
    # A log message that can be formatted either as a normal text log entry or
    # as a structured log entry suitable for Google Cloud Logging.
    #
    # A log message has a "body" which consists of either a string message, a
    # JSON object (i.e. a Hash whose values are typically strings or numbers
    # but could be nested arrays and hashes), or both. It also includes several
    # additional optional fields used by the Google Cloud Logging backend.
    #
    # Most log formatters will render the message body as a string and ignore
    # the other attributes. The {StructuredFormatter}, however, will format the
    # full message data in the JSON format understood by the Google logging
    # agent.
    #
    class Message
      ##
      # Create a log message from an input object, which can be any of:
      #
      # * An existing Message object.
      # * A Hash. Symbol keys are used as keyword arguments to the
      #   {Message#initialize} constructor. String keys are treated as fields
      #   in the JSON payload.
      # * Any other object is converted to a string with `to_s` and used as a
      #   simple text payload.
      #
      # @param input [Object] A log message input object.
      # @return [Message]
      #
      def self.from input
        case input
        when Hash
          kwargs = {}
          fields = nil
          input.each do |k, v|
            if k.is_a? Symbol
              kwargs[k] = v
            else
              (fields ||= {})[k.to_s] = v
            end
          end
          if kwargs[:fields] && fields
            kwargs[:fields].merge! fields
          else
            kwargs[:fields] ||= fields
          end
          new(**kwargs)
        when Message
          input
        else
          new message: input.to_s
        end
      end

      ##
      # Low-level constructor for a logging message.
      # All arguments are optional, with the exception that at least one of
      # `:message` and `:fields` must be provided.
      #
      # @param message [String] The main log message as a string.
      # @param fields [Hash{String=>Object}] The log message as a set of
      #     key-value pairs representing a JSON object.
      # @param timestamp [Time,Numeric,:now] The timestamp for the log entry.
      #     Can be provided as a Time object, a Numeric indicating the seconds
      #     since epoch, or `:now` to use the current time. Optional.
      # @param source_location [SourceLocation,Hash,:caller,nil] The source
      #     location for the log entry. Can be provided as a {SourceLocation}
      #     object, a Hash containing exactly the keys `:file`, `:line`, and
      #     `:function`, or `:caller` to use the location of the caller.
      #     Optional.
      # @param insert_id [String] A unique ID for this log entry that could be
      #     used on the backend to dedup messages. Optional.
      # @param trace [String] A Google Cloud Trace resource name. Optional.
      # @param span_id [String] The trace span containing this entry. Optional.
      # @param trace_sampled [boolean] Whether this trace is sampled. Optional.
      # @param labels [Hash{String=>String}] Optional metadata.
      #
      def initialize message: nil,
                     fields: nil,
                     timestamp: nil,
                     source_location: nil,
                     insert_id: nil,
                     trace: nil,
                     span_id: nil,
                     trace_sampled: nil,
                     labels: nil
        @fields = interpret_fields fields
        @message, @full_message = interpret_message message, @fields
        @timestamp = interpret_timestamp timestamp
        @source_location = interpret_source_location source_location
        @insert_id = interpret_string insert_id
        @trace = interpret_string trace
        @span_id = interpret_string span_id
        @trace_sampled = interpret_boolean trace_sampled
        @labels = interpret_labels labels
      end

      ##
      # @return [String] The message as a string. This is always present as a
      #     nonempty string, and can be reliably used as the "display" of this
      #     log entry in a list of entries.
      #
      attr_reader :message
      alias to_s message

      ##
      # @return [String] A full string representation of the message and fields
      #     as rendered in the standard logger formatter.
      #
      attr_reader :full_message
      alias inspect full_message

      ##
      # @return [Hash{String=>Object},nil] The log message as a set of
      #     key-value pairs, or nil if not present.
      #
      attr_reader :fields

      ##
      # @return [Time,nil] The timestamp for the log entry, or nil if not
      #     present.
      #
      attr_reader :timestamp

      ##
      # @return [SourceLocation,nil] The source location for the log entry, or
      #     nil if not present.
      #
      attr_reader :source_location

      ##
      # @return [String,nil] The unique ID for this log entry that could be
      #     used on the backend to dedup messages, or nil if not present.
      #
      attr_reader :insert_id

      ##
      # @return [String,nil] The Google Cloud Trace resource name, or nil if
      #     not present.
      #
      attr_reader :trace

      ##
      # @return [String,nil] The trace span containing this entry, or nil if
      #     not present.
      #
      attr_reader :span_id

      ##
      # @return [true,false,nil] Whether this trace is sampled, or nil if not
      #     present or known.
      #
      attr_reader :trace_sampled
      alias trace_sampled? trace_sampled

      ##
      # @return [Hash{String=>String},nil] Metadata, or nil if not present.
      #
      attr_reader :labels

      ##
      # @return [Hash] A hash of kwargs that can be passed to the constructor
      #     to clone this message.
      #
      def to_h
        {
          message: @message,
          fields: @fields.dup,
          timestamp: @timestamp,
          source_location: @source_location,
          insert_id: @insert_id,
          trace: @trace,
          span_id: @span_id,
          trace_sampled: @trace_sampled,
          labels: @labels.dup
        }
      end

      # @private
      def == other
        return false unless other.is_a? Message
        message == other.message &&
          fields == other.fields &&
          timestamp == other.timestamp &&
          source_location == other.source_location &&
          insert_id == other.insert_id &&
          trace == other.trace &&
          span_id == other.span_id &&
          trace_sampled? == other.trace_sampled? &&
          labels == other.labels
      end
      alias eql? ==

      # @private
      def hash
        [message, fields, timestamp, source_location, insert_id, trace, span_id, trace_sampled, labels].hash
      end

      private

      # @private
      DISALLOWED_FIELDS = [
        "severity",
        "message",
        "log",
        "httpRequest",
        "timestamp"
      ].freeze
      private_constant :DISALLOWED_FIELDS

      def interpret_fields fields
        return nil if fields.nil?
        fields = normalize_json fields
        fields.each_key do |key|
          if DISALLOWED_FIELDS.include?(key) || key.start_with?("logging.googleapis.com/")
            raise ArgumentError, "Field key not allowed: #{key}"
          end
        end
        fields
      end

      def normalize_json input
        case input
        when Hash
          input.to_h { |k, v| [k.to_s, normalize_json(v)] }
        when Array
          input.map { |v| normalize_json v }
        when Integer, Float, nil, true, false
          input
        when Rational
          if input.denominator == 1
            input.numerator
          else
            input.to_f
          end
        else
          input.to_s
        end
      end

      def interpret_message message, fields
        if message
          message = message.to_s
          full_message = fields ? "#{message} -- #{JSON.generate fields}" : message
          [message, full_message]
        else
          fields_json = JSON.generate fields
          [fields_json, fields_json]
        end
      end

      def interpret_timestamp timestamp
        case timestamp
        when Time
          timestamp
        when Numeric
          Time.at timestamp
        when :now
          Time.now.utc
        end
      end

      def interpret_source_location source_location
        case source_location
        when SourceLocation
          source_location
        when Hash
          SourceLocation.new(**source_location)
        when :caller
          SourceLocation.for_caller omit_files: [__FILE__]
        end
      end

      def interpret_string input
        input&.to_s
      end

      def interpret_boolean input
        return nil if input.nil?
        input ? true : false
      end

      def interpret_labels input
        return nil if input.nil?
        input.to_h do |k, v|
          v_converted =
            case v
            when Array, Hash
              JSON.generate v
            else
              v.to_s
            end
          [k.to_s, v_converted]
        end
      end
    end
  end
end
