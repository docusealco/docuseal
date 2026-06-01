# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::Signin
  module Types

    # Error thrown for access denied scenarios with flexible HTTP status
    # mapping
    #
    # Runtime HTTP Status Code Mapping:
    #
    # * HTTP 401 (Unauthorized): TOKEN\_EXPIRED, AUTHCODE\_EXPIRED
    # * HTTP 403 (Forbidden): USER\_CREDENTIALS\_CHANGED,
    #   INSUFFICIENT\_PERMISSIONS
    #
    # The specific HTTP status code is determined at runtime based on the
    # error enum value. Consumers should use the error field to determine
    # the specific access denial reason.
    #
    # @!attribute [rw] error
    #   OAuth 2.0 error code indicating the specific type of access denial
    #   Can be TOKEN\_EXPIRED, AUTHCODE\_EXPIRED,
    #   USER\_CREDENTIALS\_CHANGED, or INSUFFICIENT\_PERMISSIONS
    #   @return [String]
    #
    # @!attribute [rw] message
    #   Detailed message explaining the access denial Provides specific
    #   information about why access was denied
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/AccessDeniedException AWS API Documentation
    #
    class AccessDeniedException < Struct.new(
      :error,
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # AWS credentials structure containing temporary access credentials
    #
    # The scoped-down, 15 minute duration AWS credentials. Scoping down will
    # be based on CLI policy (CLI team needs to create it). Similar to cloud
    # shell implementation.
    #
    # @!attribute [rw] access_key_id
    #   AWS access key ID for temporary credentials
    #   @return [String]
    #
    # @!attribute [rw] secret_access_key
    #   AWS secret access key for temporary credentials
    #   @return [String]
    #
    # @!attribute [rw] session_token
    #   AWS session token for temporary credentials
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/AccessToken AWS API Documentation
    #
    class AccessToken < Struct.new(
      :access_key_id,
      :secret_access_key,
      :session_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input structure for CreateOAuth2Token operation
    #
    # Contains flattened token operation inputs for both authorization code
    # and refresh token flows. The operation type is determined by the
    # grant\_type parameter in the request body.
    #
    # @!attribute [rw] token_input
    #   Flattened token operation inputs The specific operation is
    #   determined by grant\_type in the request body
    #   @return [Types::CreateOAuth2TokenRequestBody]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/CreateOAuth2TokenRequest AWS API Documentation
    #
    class CreateOAuth2TokenRequest < Struct.new(
      :token_input)
      SENSITIVE = []
      include Aws::Structure
    end

    # Request body payload for CreateOAuth2Token operation
    #
    # The operation type is determined by the grant\_type parameter:
    #
    # * grant\_type=authorization\_code: Requires code, redirect\_uri,
    #   code\_verifier
    # * grant\_type=refresh\_token: Requires refresh\_token
    #
    # @!attribute [rw] client_id
    #   The client identifier (ARN) used during Sign-In onboarding Required
    #   for both authorization code and refresh token flows
    #   @return [String]
    #
    # @!attribute [rw] grant_type
    #   OAuth 2.0 grant type - determines which flow is used Must be
    #   "authorization\_code" or "refresh\_token"
    #   @return [String]
    #
    # @!attribute [rw] code
    #   The authorization code received from /v1/authorize Required only
    #   when grant\_type=authorization\_code
    #   @return [String]
    #
    # @!attribute [rw] redirect_uri
    #   The redirect URI that must match the original authorization request
    #   Required only when grant\_type=authorization\_code
    #   @return [String]
    #
    # @!attribute [rw] code_verifier
    #   PKCE code verifier to prove possession of the original code
    #   challenge Required only when grant\_type=authorization\_code
    #   @return [String]
    #
    # @!attribute [rw] refresh_token
    #   The refresh token returned from auth\_code redemption Required only
    #   when grant\_type=refresh\_token
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/CreateOAuth2TokenRequestBody AWS API Documentation
    #
    class CreateOAuth2TokenRequestBody < Struct.new(
      :client_id,
      :grant_type,
      :code,
      :redirect_uri,
      :code_verifier,
      :refresh_token)
      SENSITIVE = [:refresh_token]
      include Aws::Structure
    end

    # Output structure for CreateOAuth2Token operation
    #
    # Contains flattened token operation outputs for both authorization code
    # and refresh token flows. The response content depends on the
    # grant\_type from the original request.
    #
    # @!attribute [rw] token_output
    #   Flattened token operation outputs The specific response fields
    #   depend on the grant\_type used in the request
    #   @return [Types::CreateOAuth2TokenResponseBody]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/CreateOAuth2TokenResponse AWS API Documentation
    #
    class CreateOAuth2TokenResponse < Struct.new(
      :token_output)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response body payload for CreateOAuth2Token operation
    #
    # The response content depends on the grant\_type from the request:
    #
    # * grant\_type=authorization\_code: Returns all fields including
    #   refresh\_token and id\_token
    # * grant\_type=refresh\_token: Returns access\_token, token\_type,
    #   expires\_in, refresh\_token (no id\_token)
    #
    # @!attribute [rw] access_token
    #   Scoped-down AWS credentials (15 minute duration) Present for both
    #   authorization code redemption and token refresh
    #   @return [Types::AccessToken]
    #
    # @!attribute [rw] token_type
    #   Token type indicating this is AWS SigV4 credentials Value is
    #   "aws\_sigv4" for both flows
    #   @return [String]
    #
    # @!attribute [rw] expires_in
    #   Time to expiry in seconds (maximum 900) Present for both
    #   authorization code redemption and token refresh
    #   @return [Integer]
    #
    # @!attribute [rw] refresh_token
    #   Encrypted refresh token with cnf.jkt (SHA-256 thumbprint of
    #   presented jwk) Always present in responses (required for both flows)
    #   @return [String]
    #
    # @!attribute [rw] id_token
    #   ID token containing user identity information Present only in
    #   authorization code redemption response
    #   (grant\_type=authorization\_code) Not included in token refresh
    #   responses
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/CreateOAuth2TokenResponseBody AWS API Documentation
    #
    class CreateOAuth2TokenResponseBody < Struct.new(
      :access_token,
      :token_type,
      :expires_in,
      :refresh_token,
      :id_token)
      SENSITIVE = [:access_token, :refresh_token]
      include Aws::Structure
    end

    # Error thrown when an internal server error occurs
    #
    # HTTP Status Code: 500 Internal Server Error
    #
    # Used for unexpected server-side errors that prevent request
    # processing.
    #
    # @!attribute [rw] error
    #   OAuth 2.0 error code indicating server error Will be SERVER\_ERROR
    #   for internal server errors
    #   @return [String]
    #
    # @!attribute [rw] message
    #   Detailed message explaining the server error May include error
    #   details for debugging purposes
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/InternalServerException AWS API Documentation
    #
    class InternalServerException < Struct.new(
      :error,
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Error thrown when rate limit is exceeded
    #
    # HTTP Status Code: 429 Too Many Requests
    #
    # Possible OAuth2ErrorCode values:
    #
    # * INVALID\_REQUEST: Rate limiting, too many requests, abuse prevention
    #
    # Possible causes:
    #
    # * Too many token requests from the same client
    # * Rate limiting based on client\_id or IP address
    # * Abuse prevention mechanisms triggered
    # * Service protection against excessive token generation
    #
    # @!attribute [rw] error
    #   OAuth 2.0 error code indicating the specific type of error Will be
    #   INVALID\_REQUEST for rate limiting scenarios
    #   @return [String]
    #
    # @!attribute [rw] message
    #   Detailed message about the rate limiting May include retry-after
    #   information or rate limit details
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/TooManyRequestsError AWS API Documentation
    #
    class TooManyRequestsError < Struct.new(
      :error,
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Error thrown when request validation fails
    #
    # HTTP Status Code: 400 Bad Request
    #
    # Used for request validation errors such as malformed parameters,
    # missing required fields, or invalid parameter values.
    #
    # @!attribute [rw] error
    #   OAuth 2.0 error code indicating validation failure Will be
    #   INVALID\_REQUEST for validation errors
    #   @return [String]
    #
    # @!attribute [rw] message
    #   Detailed message explaining the validation failure Provides specific
    #   information about which validation failed
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/signin-2023-01-01/ValidationException AWS API Documentation
    #
    class ValidationException < Struct.new(
      :error,
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

  end
end

