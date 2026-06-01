# Copyright 2015 Google, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "googleauth/signet"
require "googleauth/credentials_loader"
require "multi_json"

module Google
  # Module Auth provides classes that provide Google-specific authorization
  # used to access Google APIs.
  module Auth
    # Authenticates requests using IAM credentials.
    class IAMCredentials
      SELECTOR_KEY = "x-goog-iam-authority-selector".freeze
      TOKEN_KEY = "x-goog-iam-authorization-token".freeze

      # Initializes an IAMCredentials.
      #
      # @param selector [String] The IAM selector.
      # @param token [String] The IAM token.
      # @raise [TypeError] If selector or token is not a String
      def initialize selector, token
        raise TypeError unless selector.is_a? String
        raise TypeError unless token.is_a? String
        @selector = selector
        @token = token
      end

      # Adds the credential fields to the hash.
      #
      # @param a_hash [Hash] The hash to update with credentials
      # @return [Hash] The updated hash with credentials
      def apply! a_hash
        a_hash[SELECTOR_KEY] = @selector
        a_hash[TOKEN_KEY] = @token
        a_hash
      end

      # Returns a clone of a_hash updated with the authorization header
      #
      # @param a_hash [Hash] The hash to clone and update with credentials
      # @return [Hash] A new hash with credentials
      def apply a_hash
        a_copy = a_hash.clone
        apply! a_copy
        a_copy
      end

      # Returns a reference to the #apply method, suitable for passing as
      # a closure
      #
      # @return [Proc] A procedure that updates a hash with credentials
      def updater_proc
        proc { |a_hash, _opts = {}| apply a_hash }
      end

      # Returns the IAM authority selector as the principal
      # @private
      # @return [String] the IAM authoirty selector
      def principal
        @selector
      end
    end
  end
end
