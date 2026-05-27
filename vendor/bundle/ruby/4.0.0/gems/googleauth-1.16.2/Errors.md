# Error Handling in Google Auth Library for Ruby

## Overview

The Google Auth Library for Ruby provides a structured approach to error handling. This document explains the error hierarchy, how to access detailed error information, and provides examples of handling errors effectively.

## Error Hierarchy

The Google Auth Library has two main error hierarchies: the core authentication errors and the specialized ID token flow errors.

### Core Authentication Errors

These errors are used throughout the main library for general authentication and credential operations:

```
Google::Auth::Error (module)
  ├── Google::Auth::InitializationError (class)
  └── Google::Auth::DetailedError (module)
      ├── Google::Auth::CredentialsError (class)
      ├── Google::Auth::AuthorizationError (class)
      ├── Google::Auth::UnexpectedStatusError (class)
      └── Google::Auth::ParseError (class)
```

### ID Token Errors

These specialized errors are used specifically for ID token flow. They also include the `Google::Auth::Error` module, allowing them to be caught with the same error handling as the core authentication errors:

```
Google::Auth::Error (module)
  ├── Google::Auth::IDTokens::KeySourceError (class)
  └── Google::Auth::IDTokens::VerificationError (class)
      ├── ExpiredTokenError (class)
      ├── SignatureError (class)
      ├── IssuerMismatchError (class)
      ├── AudienceMismatchError (class)
      └── AuthorizedPartyMismatchError (class)
```

### Error Module Types

- **`Google::Auth::Error`**: Base module that all Google Auth errors include. Use this to catch any error from the library.

- **`Google::Auth::DetailedError`**: Extends `Error` to include detailed information about the credential that caused the error, including the credential type and principal.

## Core Authentication Error Classes

- **`InitializationError`**: Raised during credential initialization when required parameters are missing or invalid.

- **`CredentialsError`**: Generic error raised during authentication flows.

- **`AuthorizationError`**: Raised when a remote server refuses to authorize the client. Inherits from `Signet::AuthorizationError`. Is being raised where `Signet::AuthorizationError` was raised previously.

- **`UnexpectedStatusError`**: Raised when a server returns an unexpected HTTP status code. Inherits from `Signet::UnexpectedStatusError`. Is being raised where `Signet::UnexpectedStatusError` was raised previously.

- **`ParseError`**: Raised when the client fails to parse a value from a response. Inherits from `Signet::ParseError`. Is being raised where `Signet::ParseError` was raised previously.

## Detailed Error Information

Errors that include the `DetailedError` module provide additional context about what went wrong:

- **`credential_type_name`**: The class name of the credential that raised the error (e.g., `"Google::Auth::ServiceAccountCredentials"`)

- **`principal`**: The identity associated with the credentials (e.g., an email address for service accounts, `:api_key` for API key credentials)

### Example: Catching and Handling Core Errors

```ruby
begin
  credentials = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open("your-key.json")
  )
  # Use credentials...
rescue Google::Auth::InitializationError => e
  puts "Failed to initialize credentials: #{e.message}"
  # e.g., Missing required fields in the service account key file
rescue Google::Auth::DetailedError => e
  puts "Authorization failed: #{e.message}"
  puts "Credential type: #{e.credential_type_name}"
  puts "Principal: #{e.principal}"
  # e.g., Invalid or revoked service account
rescue Google::Auth::Error => e
  puts "Unknown Google Auth error: #{e.message}"
end
```

## Backwards compatibility

Some classes in the Google Auth Library raise standard Ruby `ArgumentError` and `TypeError`. These errors are preserved for backward compatibility, however the new code will raise `Google::Auth::InitializationError` instead.

## ID Token Verification

The Google Auth Library includes functionality for verifying ID tokens through the `Google::Auth::IDTokens` namespace. These operations have their own specialized error classes that also include the `Google::Auth::Error` module, allowing them to be caught with the same error handling as other errors in the library.

### ID Token Error Classes

- **`KeySourceError`**: Raised when the library fails to obtain the keys needed to verify a token, typically from a JWKS (JSON Web Key Set) endpoint.

- **`VerificationError`**: Base class for all errors related to token verification failures.

- **`ExpiredTokenError`**: Raised when a token has expired according to its expiration time claim (`exp`).

- **`SignatureError`**: Raised when a token's signature cannot be verified, indicating it might be tampered with or corrupted.

- **`IssuerMismatchError`**: Raised when a token's issuer (`iss` claim) doesn't match the expected issuer.

- **`AudienceMismatchError`**: Raised when a token's audience (`aud` claim) doesn't match the expected audience.

- **`AuthorizedPartyMismatchError`**: Raised when a token's authorized party (`azp` claim) doesn't match the expected client ID.

### Example: Handling ID Token Verification Errors

```ruby
require "googleauth/id_tokens"

begin
  # Verify the provided ID token
  payload = Google::Auth::IDTokens.verify_oidc(
    id_token,
    audience: "expected-audience-12345.apps.googleusercontent.com"
  )
  
  # Use the verified token payload
  user_email = payload["email"]
  
rescue Google::Auth::IDTokens::ExpiredTokenError => e
  puts "The token has expired. Please obtain a new one."

rescue Google::Auth::IDTokens::SignatureError => e
  puts "Invalid token signature."

rescue Google::Auth::IDTokens::IssuerMismatchError => e
  puts "Invalid token issuer."

rescue Google::Auth::IDTokens::AudienceMismatchError => e
  puts "This token is not intended for this application (invalid audience)."
  
rescue Google::Auth::IDTokens::AuthorizedPartyMismatchError => e
  puts "Invalid token authorized party."

rescue Google::Auth::IDTokens::VerificationError => e
  puts "Token verification failed: #{e.message}"
  # Generic verification error handling
  
rescue Google::Auth::IDTokens::KeySourceError => e
  puts "Unable to retrieve verification keys: #{e.message}"
  
rescue Google::Auth::Error => e
  puts "Unknown Google Auth error: #{e.message}"
  # This will catch any Google Auth error
end
```
