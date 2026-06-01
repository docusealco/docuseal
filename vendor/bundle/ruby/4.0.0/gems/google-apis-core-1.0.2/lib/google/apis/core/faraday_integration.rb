# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "faraday"
require "faraday/follow_redirects"

module Google
  module Apis
    module Core
      # Customized version of the FollowRedirects middleware that does not
      # trigger on 308. HttpCommand wants to handle 308 itself for resumable
      # uploads.
      class FollowRedirectsMiddleware < Faraday::FollowRedirects::Middleware
        def follow_redirect?(env, response)
          super && response.status != 308
        end
      end

      Faraday::Response.register_middleware(follow_redirects_google_apis_core: FollowRedirectsMiddleware)

      # Customized subclass of Faraday::Response with additional capabilities
      # needed by older versions of some downstream dependencies.
      class Response < Faraday::Response
        # Compatibility alias.
        # Earlier versions based on the old `httpclient` gem used `HTTP::Message`,
        # which defined the `header` field that some clients, notably
        # google-cloud-storage, depend on.
        # Faraday's `headers` isn't an exact replacement because its values are
        # single strings whereas `HTTP::Message` values are arrays, but
        # google-cloud-storage already passes the result through `Array()` so this
        # should work sufficiently.
        alias header headers
      end
    end
  end
end
