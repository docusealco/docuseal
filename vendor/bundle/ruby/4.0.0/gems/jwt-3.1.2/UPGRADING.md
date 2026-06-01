# Upgrading ruby-jwt to >= 3.0.0

## Removal of the indirect [RbNaCl](https://github.com/RubyCrypto/rbnacl) dependency

Historically, the set of supported algorithms was extended by including the `rbnacl` gem in the application's Gemfile. On load, ruby-jwt tried to load the gem and, if available, extend the algorithms to those provided by the `rbnacl/libsodium` libraries. This indirect dependency has caused some maintenance pain and confusion about which versions of the gem are supported.

Some work to ease the way alternative algorithms can be implemented has been done. This enables the extraction of the algorithm provided by `rbnacl`.

The extracted algorithms now live in the [jwt-eddsa](https://rubygems.org/gems/jwt-eddsa) gem.

### Dropped support for HS512256

The algorithm HS512256 (HMAC-SHA-512 truncated to 256-bits) is not part of any JWA/JWT RFC and therefore will not be supported anymore. It was part of the HMAC algorithms provided by the indirect [RbNaCl](https://github.com/RubyCrypto/rbnacl) dependency. Currently, there are no direct substitutes for the algorithm.

### `JWT::EncodedToken#payload` will raise before token is verified

To avoid accidental use of unverified tokens, the `JWT::EncodedToken#payload` method will raise an error if accessed before the token signature has been verified.

To access the payload before verification, use the method `JWT::EncodedToken#unverified_payload`.

## Stricter requirements on Base64 encoded data

Base64 decoding will no longer fallback on the looser RFC 2045. The biggest difference is that the looser version was ignoring whitespaces and newlines, whereas the stricter version raises errors in such cases.

If you, for example, read tokens from files, there could be problems with trailing newlines. Make sure you trim your input before passing it to the decoding mechanisms.

## Claim verification revamp

Claim verification has been [split into separate classes](https://github.com/jwt/ruby-jwt/pull/605) and has [a new API](https://github.com/jwt/ruby-jwt/pull/626), leading to the following deprecations:

- The `::JWT::ClaimsValidator` class will be removed in favor of the functionality provided by `::JWT::Claims`.
- The `::JWT::Claims::verify!` method will be removed in favor of `::JWT::Claims::verify_payload!`.
- The `::JWT::JWA.create` method will be removed.
- The `::JWT::Verify` class will be removed in favor of the functionality provided by `::JWT::Claims`.
- Calling `::JWT::Claims::Numeric.new` with a payload will be removed in favor of `::JWT::Claims::verify_payload!(payload, :numeric)`.
- Calling `::JWT::Claims::Numeric.verify!` with a payload will be removed in favor of `::JWT::Claims::verify_payload!(payload, :numeric)`.

## Algorithm restructuring

The internal algorithms were [restructured](https://github.com/jwt/ruby-jwt/pull/607) to support extensions from separate libraries. The changes led to a few deprecations and new requirements:

- The `sign` and `verify` static methods on all the algorithms (`::JWT::JWA`) will be removed.
- Custom algorithms are expected to include the `JWT::JWA::SigningAlgorithm` module.

## Base64 the `k´ value for HMAC JWKs

The gem was missing the Base64 encoding and decoding when representing and parsing a HMAC key as a JWK. This issue is now addressed. The added encoding will break compatibility with JWKs produced by older versions of the gem.
