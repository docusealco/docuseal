# Introduction

The closest thing to a base credentials class is the `BaseClient` module. 
It includes functionality common to most credentials, such as applying authentication tokens to request headers, managing token expiration and refresh, handling logging, and providing updater procs for API clients.

Many credentials classes inherit from `Signet::OAuth2::Client` (`lib/googleauth/signet.rb`) class which provides OAuth-based authentication.
The `Signet::OAuth2::Client` includes the `BaseClient` functionality.

Most credential types either inherit from `Signet::OAuth2::Client` or include the `BaseClient` module directly.

Notably, `Google::Auth::Credentials` (`lib/googleauth/credentials.rb`) is not a base type or a credentials type per se. It is a wrapper for other credential classes
that exposes common initialization functionality, such as creating credentials from environment variables, default paths, or application defaults. It is used and subclassed by Google's API client libraries.

# List of credentials types

## Simple Authentication (non-OAuth)

**Google::Auth::APIKeyCredentials** - `lib/googleauth/api_key.rb`
   - Includes `Google::Auth::BaseClient` module
   - Implements Google API Key authentication
   - API Keys are text strings that don't have an associated JSON file
   - API Keys provide project information but don't reference an IAM principal
   - They do not expire and cannot be refreshed
   - Can be loaded from the `GOOGLE_API_KEY` environment variable

2. **Google::Auth::BearerTokenCredentials** - `lib/googleauth/bearer_token.rb`
   - Includes `Google::Auth::BaseClient` module
   - Implements Bearer Token authentication
   - Bearer tokens are strings representing an authorization grant
   - Can be OAuth2 tokens, JWTs, ID tokens, or any token sent as a `Bearer` in an `Authorization` header
   - Used when the end-user is managing the token separately (e.g., with another service)
   - Token lifetime tracking and refresh are outside this class's scope
   - No JSON representation for this type of credentials

## GCP-Specialized authentication

3. **Google::Auth::GCECredentials < Signet::OAuth2::Client** - `lib/googleauth/compute_engine.rb`
   - For obtaining authentication tokens from GCE metadata server
   - Used automatically when code is running on Google Compute Engine
   - Fetches tokens from the metadata server with no additional configuration needed
   - This credential type does not have a supported JSON form

4. **Google::Auth::IAMCredentials < Signet::OAuth2::Client** - `lib/googleauth/iam.rb`
   - For IAM-based authentication (e.g. service-to-service)
   - Implements authentication-as-a-service for systems already authenticated
   - Exchanges existing credentials for a short-lived access token
   - This credential type does not have a supported JSON form

## Service Account Authentication

5. **Google::Auth::ServiceAccountCredentials < Signet::OAuth2::Client** - `lib/googleauth/service_account.rb`
   - Authenticates requests using Service Account credentials via an OAuth access token
   - Created from JSON key file downloaded from Google Cloud Console. The JSON form of this credential type has a `"type"` field with the value `"service_account"`.
   - Supports both OAuth access tokens and self-signed JWT authentication
   - Can specify scopes for access token requests

6. **Google::Auth::ServiceAccountJwtHeaderCredentials** - `lib/googleauth/service_account_jwt_header.rb`
   - Authenticates using Service Account credentials with JWT headers
   - Typically used via `ServiceAccountCredentials` and not by itself
   - Creates JWT directly for making authenticated calls
   - Does not require a round trip to the authorization server
   - Doesn't support OAuth scopes - uses audience (target API) instead

7. **Google::Auth::ImpersonatedServiceAccountCredentials < Signet::OAuth2::Client** - `lib/googleauth/impersonated_service_account.rb`
   - For service account impersonation
   - Allows a GCP principal identified by a set of source credentials to impersonate a service account
   - Useful for delegation of authority and managing permissions across service accounts
   - Source credentials must have the Service Account Token Creator role on the target
   - This credential type supports JSON configuration. The JSON form of this credential type has a `"type"` field with the value `"impersonated_service_account"`.

## User Authentication

8. **Google::Auth::UserRefreshCredentials < Signet::OAuth2::Client** - `lib/googleauth/user_refresh.rb`
   - For user refresh token authentication (from 3-legged OAuth flow)
   - Authenticates on behalf of a user who has authorized the application
   - Handles token refresh when original access token expires
   - Typically obtained through web or installed application flow. The JSON form of this credential type has a `"type"` field with the value `"authorized_user"`.

`Google::Auth::UserAuthorizer` (`lib/googleauth/user_authorizer.rb`) and `Google::Auth::WebUserAuthorizer` (`lib/googleauth/web_user_authorizer.rb`)
 are used to facilitate user authentication. The `UserAuthorizer` handles interactive 3-Legged-OAuth2 (3LO) user consent authorization for command-line applications.
 The `WebUserAuthorizer` is a variation of UserAuthorizer adapted for Rack-based web applications that manages OAuth state and provides callback handling.

## External Account Authentication
  `Google::Auth::ExternalAccount::Credentials` (`lib/googleauth/external_account.rb`) is not a credentials type, it is a module
  that procides an entry point for External Account credentials. It also serves as a factory that creates appropriate credential
  types based on credential source (similar to `Google::Auth::get_application_default`).
  It is included in all External Account credentials types, and it itself includes `Google::Auth::BaseClient` module so all External
  Account credentials types include `Google::Auth::BaseClient`.
  The JSON form of this credential type has a `"type"` field with the value `"external_account"`.

9. **Google::Auth::ExternalAccount::AwsCredentials** - `lib/googleauth/external_account/aws_credentials.rb`
     - Includes `Google::Auth::BaseClient` module
     - Includes `ExternalAccount::BaseCredentials` module
     - Uses AWS credentials to authenticate to Google Cloud
     - Exchanges temporary AWS credentials for Google access tokens
     - Used for workloads running on AWS that need to access Google Cloud

10. **Google::Auth::ExternalAccount::IdentityPoolCredentials** - `lib/googleauth/external_account/identity_pool_credentials.rb`
     - Includes `Google::Auth::BaseClient` module
     - Includes `ExternalAccount::BaseCredentials` module
     - Authenticates using external identity pool
     - Exchanges external identity tokens for Google access tokens
     - Supports file-based and URL-based credential sources

11. **Google::Auth::ExternalAccount::PluggableCredentials** - `lib/googleauth/external_account/pluggable_credentials.rb`
     - Includes `Google::Auth::BaseClient` module
     - Includes `ExternalAccount::BaseCredentials` module
     - Supports executable-based credential sources
     - Executes external programs to retrieve credentials
     - Allows for custom authentication mechanisms via external executables
