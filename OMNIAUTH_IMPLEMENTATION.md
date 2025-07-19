# DocuSeal Omniauth Implementation Guide

This document describes the complete implementation of omniauth/SSO functionality in DocuSeal, restoring the features that were previously gated behind paywall checks.

## Overview

We have successfully implemented comprehensive omniauth support with the following providers:
- **SAML 2.0** - For enterprise SSO integration
- **Google OAuth2** - For Google account authentication  
- **Microsoft Graph** - For Microsoft/Office 365 authentication

## What Was Implemented

### 1. Database Schema Changes
- Added `provider` and `uid` columns to the `users` table
- Created migration: `db/migrate/20250719104801_add_omniauth_to_users.rb`
- Added unique index on `[provider, uid]` combination

### 2. User Model Updates
- Added `:omniauthable` to Devise modules
- Configured omniauth providers: `%i[saml google_oauth2 microsoft_graph]`
- Implemented `User.from_omniauth(auth)` class method for handling authentication callbacks
- Added support for both single-tenant and multi-tenant account creation

### 3. Devise Configuration
- Updated `config/initializers/devise.rb` with omniauth provider configurations
- Added environment variable-based configuration for SAML
- Configured Google OAuth2 and Microsoft Graph providers
- Added proper attribute mapping for SAML assertions

### 4. Controllers
- Created `app/controllers/users/omniauth_callbacks_controller.rb`
- Handles callbacks for all three providers (SAML, Google, Microsoft)
- Includes proper error handling and session management
- Updated `app/controllers/sso_settings_controller.rb` with configuration management

### 5. Views and UI
- Replaced SSO paywall placeholder with functional SAML configuration form
- Updated login form to include all three authentication providers
- Added SSO settings interface for SAML configuration
- Removed `Docuseal.multitenant?` checks that were gating SSO features

### 6. Routes
- Updated routes to include omniauth callbacks
- Added update action to SSO settings controller
- Enabled SSO settings for all users (removed paywall restrictions)

### 7. Gemfile Dependencies
Added the following gems:
```ruby
gem 'omniauth'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-saml'
gem 'omniauth-google-oauth2'
gem 'omniauth-microsoft_graph'
```

### 8. Development Environment
- Created `Dockerfile.dev` for development with mounted codebase
- Created `docker-compose.dev.yml` for local development environment
- Configured development environment with PostgreSQL and Redis

## Configuration

### SAML Configuration

#### Environment Variables
Set these environment variables for SAML configuration:
```bash
SAML_IDP_SSO_SERVICE_URL=https://your-idp.com/sso/saml
SAML_IDP_CERT_FINGERPRINT=AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
SAML_SP_ENTITY_ID=docuseal
APP_URL=http://localhost:3000
```

#### Database Configuration
Alternatively, configure SAML through the web interface at `/settings/sso` which stores encrypted configuration in the database.

#### Service Provider URLs
Provide these URLs to your Identity Provider:
- **Assertion Consumer Service URL**: `http://localhost:3000/users/auth/saml/callback`
- **SP Metadata URL**: `http://localhost:3000/users/auth/saml/metadata`
- **SP Entity ID**: `docuseal` (or your custom value)

### Google OAuth2 Configuration

Add to Rails credentials or environment variables:
```bash
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

### Microsoft Graph Configuration

Add to Rails credentials or environment variables:
```bash
MICROSOFT_CLIENT_ID=your-microsoft-client-id
MICROSOFT_CLIENT_SECRET=your-microsoft-client-secret
```

## Usage

### For Users
1. Navigate to the login page
2. Choose from available authentication methods:
   - Sign in with Google
   - Sign in with Microsoft
   - Sign in with SAML SSO (if configured)
3. Complete authentication with your chosen provider
4. You'll be automatically signed in or prompted to complete registration

### For Administrators
1. Go to Settings → SSO
2. Configure SAML settings with your Identity Provider details
3. Test the configuration using the "Test SAML Login" button
4. Users can now authenticate using the configured SSO provider

## Development Setup

### Using Docker (Recommended)
```bash
# Build the development environment
docker-compose -f docker-compose.dev.yml build

# Start the development environment
docker-compose -f docker-compose.dev.yml up

# Access the application at http://localhost:3000
```

### Local Development
```bash
# Install dependencies
bundle install
yarn install

# Run database migrations
rails db:create db:migrate

# Start the development server
rails server
```

## Testing

### SAML Testing
1. Set up environment variables for SAML configuration
2. Navigate to `/settings/sso` to configure SAML
3. Use the "Test SAML Login" button to verify configuration
4. Check logs for any authentication errors

### OAuth Testing
1. Configure Google/Microsoft credentials
2. Navigate to login page
3. Click "Sign in with Google" or "Sign in with Microsoft"
4. Complete OAuth flow and verify user creation/authentication

## Security Considerations

1. **CSRF Protection**: Implemented via `omniauth-rails_csrf_protection` gem
2. **Secure Credentials**: Store sensitive configuration in Rails credentials or environment variables
3. **Certificate Validation**: SAML certificate fingerprints are validated
4. **Session Management**: Proper session cleanup and management implemented

## Troubleshooting

### Common Issues

1. **"NameError: uninitialized constant EncryptedConfig"**
   - This was resolved by moving SAML configuration to environment variables
   - Ensure proper initialization order in Devise configuration

2. **"Invalid credentials" errors**
   - Verify OAuth client IDs and secrets are correct
   - Check redirect URIs match exactly

3. **SAML authentication failures**
   - Verify IdP certificate fingerprint is correct
   - Check that assertion consumer service URL matches
   - Ensure name identifier format matches IdP configuration

### Logs
Check application logs for detailed error messages:
```bash
docker-compose -f docker-compose.dev.yml logs app
```

## Files Modified/Created

### New Files
- `db/migrate/20250719104801_add_omniauth_to_users.rb`
- `app/controllers/users/omniauth_callbacks_controller.rb`
- `app/views/sso_settings/_saml_form.html.erb`
- `Dockerfile.dev`
- `docker-compose.dev.yml`
- `OMNIAUTH_IMPLEMENTATION.md`

### Modified Files
- `Gemfile` - Added omniauth gems
- `app/models/user.rb` - Added omniauthable and from_omniauth method
- `config/initializers/devise.rb` - Added omniauth provider configurations
- `app/controllers/sso_settings_controller.rb` - Added update method
- `app/views/sso_settings/index.html.erb` - Replaced placeholder with form
- `app/views/devise/sessions/new.html.erb` - Added omniauth provider buttons
- `app/views/shared/_settings_nav.html.erb` - Removed paywall check
- `config/routes.rb` - Added update route for SSO settings

## Next Steps

1. **Production Deployment**: Configure production environment variables
2. **Additional Providers**: Add more omniauth providers as needed
3. **Advanced SAML**: Implement IdP-initiated SSO and SLO (Single Logout)
4. **User Management**: Add admin interface for managing SSO users
5. **Audit Logging**: Add logging for SSO authentication events

## Support

For issues or questions about this implementation, refer to:
- [Devise Omniauth Documentation](https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview)
- [Omniauth SAML Documentation](https://github.com/omniauth/omniauth-saml)
- DocuSeal application logs and error messages
