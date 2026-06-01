# Copyright 2014 Google LLC
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


require "googleauth"

module Google
  module Cloud
    module Storage
      ##
      # # Credentials
      #
      # Represents the authentication and authorization used to connect to the
      # Storage API.
      #
      # @example
      #   # The recommended way to provide credentials is to use the `make_creds` method
      #   # on the appropriate credentials class for your environment.
      #
      #   require "googleauth"
      #   require "google/cloud/storage"
      #
      #   credentials = ::Google::Auth::ServiceAccountCredentials.make_creds(
      #     json_key_io: ::File.open("/path/to/keyfile.json"),
      #     scope: "https://www.googleapis.com/auth/devstorage.full_control"
      #   )
      #
      #   storage = Google::Cloud::Storage.new(
      #     project_id: "my-project",
      #     credentials: credentials
      #   )
      #
      #   storage.project_id #=> "my-project"
      #
      # @note Warning: If you accept a credential configuration (JSON file or Hash) from an
      #   external source for authentication to Google Cloud, you must validate it before
      #   providing it to a Google API client library. Providing an unvalidated credential
      #   configuration to Google APIs can compromise the security of your systems and data.
      #
      class Credentials < Google::Auth::Credentials
        SCOPE = ["https://www.googleapis.com/auth/devstorage.full_control"].freeze
        PATH_ENV_VARS = [
          "STORAGE_CREDENTIALS",
          "STORAGE_KEYFILE",
          "GOOGLE_CLOUD_CREDENTIALS",
          "GOOGLE_CLOUD_KEYFILE",
          "GCLOUD_KEYFILE"
        ].freeze
        JSON_ENV_VARS = [
          "STORAGE_CREDENTIALS_JSON",
          "STORAGE_KEYFILE_JSON",
          "GOOGLE_CLOUD_CREDENTIALS_JSON",
          "GOOGLE_CLOUD_KEYFILE_JSON",
          "GCLOUD_KEYFILE_JSON"
        ].freeze
        DEFAULT_PATHS = ["~/.config/gcloud/application_default_credentials.json"].freeze
      end
    end
  end
end
