# OpenID Connect (OIDC) with ruby-oauth/oauth2

## OIDC Libraries

Libraries built on top of the oauth2 gem that implement OIDC.

- [gamora](https://github.com/amco/gamora-rb) - OpenID Connect Relying Party for Rails apps
- [omniauth-doximity-oauth2](https://github.com/doximity/omniauth-doximity-oauth2) - OmniAuth strategy for Doximity, supporting OIDC, and using PKCE
- [omniauth-himari](https://github.com/sorah/himari) - OmniAuth strategy to act as OIDC RP and use [Himari](https://github.com/sorah/himari) for OP
- [omniauth-mit-oauth2](https://github.com/MITLibraries/omniauth-mit-oauth2) - OmniAuth strategy for MIT OIDC

If any other libraries would like to be added to this list, please open an issue or pull request.

## Raw OIDC with ruby-oauth/oauth2

This document complements the inline documentation by focusing on OpenID Connect (OIDC) 1.0 usage patterns when using this gem as an OAuth 2.0 client library.

Scope of this document

- Audience: Developers building an OAuth 2.0/OIDC Relying Party (RP, aka client) in Ruby.
- Non-goals: This gem does not implement an OIDC Provider (OP, aka Authorization Server); for OP/server see other projects (e.g., doorkeeper + oidc extensions).
- Status: Informational documentation with links to normative specs. The gem intentionally remains protocol-agnostic beyond OAuth 2.0; OIDC specifics (like ID Token validation) must be handled by your application.

Key concepts refresher

- OAuth 2.0 delegates authorization; it does not define authentication of the end-user.
- OIDC layers an identity layer on top of OAuth 2.0, introducing:
  - ID Token: a JWT carrying claims about the authenticated end-user and the authentication event.
  - Standardized scopes: openid (mandatory), profile, email, address, phone, offline_access, and others.
  - UserInfo endpoint: a protected resource for retrieving user profile claims.
  - Discovery and Dynamic Client Registration (optional for providers/clients that support them).

What this gem provides for OIDC

- All OAuth 2.0 client capabilities required for OIDC flows: building authorization requests, exchanging authorization codes, refreshing tokens, and making authenticated resource requests.
- Transport and parsing conveniences (snaky hash, Faraday integration, error handling, etc.).
- Optional client authentication schemes useful with OIDC deployments:
  - basic_auth (default)
  - request_body (legacy)
  - tls_client_auth (MTLS)
  - private_key_jwt (OIDC-compliant when configured per OP requirements)

What you must add in your app for OIDC

- ID Token validation: This gem surfaces id_token values but does not verify them. Your app should:
  1) Parse the JWT (header, payload, signature)
  2) Fetch the OP JSON Web Key Set (JWKS) from discovery (or configure statically)
  3) Select the correct key by kid (when present) and verify the signature and algorithm
  4) Validate standard claims (iss, aud, exp, iat, nbf, azp, nonce when used, at_hash/c_hash when applicable)
  5) Enforce expected client_id, issuer, and clock skew policies
- Nonce handling for Authorization Code flow with OIDC: generate a cryptographically-random nonce, bind it to the user session before redirect, include it in authorize request, and verify it in the ID Token on return.
- PKCE is best practice and often required by OPs: generate/verifier, send challenge in authorize, send verifier in token request.
- Session/state management: continue to validate state to mitigate CSRF; use exact redirect_uri matching.

Minimal OIDC Authorization Code example

```ruby
require "oauth2"
require "jwt"         # jwt/ruby-jwt
require "net/http"
require "json"

client = OAuth2::Client.new(
  ENV.fetch("OIDC_CLIENT_ID"),
  ENV.fetch("OIDC_CLIENT_SECRET"),
  site: ENV.fetch("OIDC_ISSUER"),              # e.g. https://accounts.example.com
  authorize_url: "/authorize",                 # or discovered
  token_url: "/token",                         # or discovered
)

# Step 1: Redirect to OP for consent/auth
state = SecureRandom.hex(16)
nonce = SecureRandom.hex(16)
pkce_verifier = SecureRandom.urlsafe_base64(64)
pkce_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(pkce_verifier)).delete("=")

authz_url = client.auth_code.authorize_url(
  scope: "openid profile email",
  state: state,
  nonce: nonce,
  code_challenge: pkce_challenge,
  code_challenge_method: "S256",
  redirect_uri: ENV.fetch("OIDC_REDIRECT_URI"),
)
# redirect_to authz_url

# Step 2: Handle callback
# params[:code], params[:state]
raise "state mismatch" unless params[:state] == state

token = client.auth_code.get_token(
  params[:code],
  redirect_uri: ENV.fetch("OIDC_REDIRECT_URI"),
  code_verifier: pkce_verifier,
)

# The token may include: access_token, id_token, refresh_token, etc.
id_token = token.params["id_token"] || token.params[:id_token]

# Step 3: Validate the ID Token (simplified – add your own checks!)
# Discover keys (example using .well-known)
issuer = ENV.fetch("OIDC_ISSUER")
jwks_uri = JSON.parse(Net::HTTP.get(URI.join(issuer, "/.well-known/openid-configuration"))).
  fetch("jwks_uri")
jwks = JSON.parse(Net::HTTP.get(URI(jwks_uri)))
keys = jwks.fetch("keys")

# Use ruby-jwt JWK loader
jwk_set = JWT::JWK::Set.new(keys.map { |k| JWT::JWK.import(k) })

decoded, headers = JWT.decode(
  id_token,
  nil,
  true,
  algorithms: ["RS256", "ES256", "PS256"],
  jwks: jwk_set,
  verify_iss: true,
  iss: issuer,
  verify_aud: true,
  aud: ENV.fetch("OIDC_CLIENT_ID"),
)

# Verify nonce
raise "nonce mismatch" unless decoded["nonce"] == nonce

# Optionally: call UserInfo
userinfo = token.get("/userinfo").parsed
```

Notes on discovery and registration

- Discovery: Most OPs publish configuration at `{issuer}/.well-known/openid-configuration` (OIDC Discovery 1.0). From there, resolve authorization_endpoint, token_endpoint, jwks_uri, userinfo_endpoint, etc.
- Dynamic Client Registration: Some OPs allow registering clients programmatically (OIDC Dynamic Client Registration 1.0). This gem does not implement registration; use a plain HTTP client or Faraday and store credentials securely.

Common pitfalls and tips

- Always request the openid scope when you expect an ID Token. Without it, the OP may behave as vanilla OAuth 2.0.
- Validate ID Token signature and claims before trusting any identity data. Do not rely solely on the presence of an id_token field.
- Prefer Authorization Code + PKCE. Avoid Implicit; it is discouraged in modern guidance and may be disabled by providers.
- Use exact redirect_uri matching, and keep your allow-list short.
- For public clients that use refresh tokens, prefer sender-constrained tokens (DPoP/MTLS) or rotation with one-time-use refresh tokens, per modern best practices.
- When using private_key_jwt, ensure the "aud" (or token_url) and "iss/sub" claims are set per the OP’s rules, and include kid in the JWT header when required so the OP can select the right key.

Relevant specifications and references

- OpenID Connect Core 1.0: https://openid.net/specs/openid-connect-core-1_0.html
- OIDC Core (final): https://openid.net/specs/openid-connect-core-1_0-final.html
- How OIDC works: https://openid.net/developers/how-connect-works/
- OpenID Connect home: https://openid.net/connect/
- OIDC Discovery 1.0: https://openid.net/specs/openid-connect-discovery-1_0.html
- OIDC Dynamic Client Registration 1.0: https://openid.net/specs/openid-connect-registration-1_0.html
- OIDC Session Management 1.0: https://openid.net/specs/openid-connect-session-1_0.html
- OIDC RP-Initiated Logout 1.0: https://openid.net/specs/openid-connect-rpinitiated-1_0.html
- OIDC Back-Channel Logout 1.0: https://openid.net/specs/openid-connect-backchannel-1_0.html
- OIDC Front-Channel Logout 1.0: https://openid.net/specs/openid-connect-frontchannel-1_0.html
- Auth0 OIDC overview: https://auth0.com/docs/authenticate/protocols/openid-connect-protocol
- Spring Authorization Server’s list of OAuth2/OIDC specs: https://github.com/spring-projects/spring-authorization-server/wiki/OAuth2-and-OIDC-Specifications

See also

- README sections on OAuth 2.1 notes and OIDC notes
- Strategy classes under lib/oauth2/strategy for flow helpers
- Specs under spec/oauth2 for concrete usage patterns

Contributions welcome

- If you discover provider-specific nuances, consider contributing examples or clarifications (without embedding provider-specific hacks into the library).
