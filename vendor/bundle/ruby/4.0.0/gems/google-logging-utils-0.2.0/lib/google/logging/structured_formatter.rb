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
require "google/logging/message"

module Google
  module Logging
    ##
    # A log formatter that outputs the JSON-based structured logging format
    # (https://cloud.google.com/logging/docs/structured-logging) understood by
    # Google's logging agent.
    #
    class StructuredFormatter
      # @private
      CLOUD_SEVERITY = Hash.new { |_h, k| k }.merge(
        "WARN" => "WARNING",
        "FATAL" => "CRITICAL",
        "ANY" => "DEFAULT"
      ).freeze

      # @private
      def call severity, time, progname, msg
        msg = Message.from msg
        time = msg.timestamp || time
        struct = {
          "severity" => CLOUD_SEVERITY[severity],
          "message" => msg.message,
          "timestamp" => {
            "seconds" => time.to_i,
            "nanos" => time.nsec
          }
        }
        struct.merge! msg.fields if msg.fields
        struct["logging.googleapis.com/sourceLocation"] = msg.source_location.to_h if msg.source_location
        struct["logging.googleapis.com/insertId"] = msg.insert_id if msg.insert_id
        struct["logging.googleapis.com/spanId"] = msg.span_id if msg.span_id
        struct["logging.googleapis.com/trace"] = msg.trace if msg.trace
        struct["logging.googleapis.com/traceSampled"] = msg.trace_sampled if msg.trace_sampled
        struct["logging.googleapis.com/labels"] = msg.labels if msg.labels
        struct["progname"] ||= progname if progname
        content = JSON.generate struct
        "#{content}\n"
      end
    end
  end
end
