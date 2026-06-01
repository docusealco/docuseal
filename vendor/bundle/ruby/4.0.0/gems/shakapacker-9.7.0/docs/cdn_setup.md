# CDN Setup Guide for Shakapacker

This guide explains how to configure Shakapacker to serve your JavaScript bundles and other assets from a Content Delivery Network (CDN) like CloudFlare, CloudFront, or Fastly.

## Table of Contents

- [Overview](#overview)
- [Configuration Methods](#configuration-methods)
- [Step-by-Step Setup](#step-by-step-setup)
- [CloudFlare Specific Setup](#cloudflare-specific-setup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Overview

When using a CDN with Shakapacker, your compiled JavaScript bundles and other assets will be served from the CDN's edge servers instead of your application server. This provides:

- **Reduced latency** for users around the world
- **Decreased load** on your application servers
- **Better caching** and faster asset delivery
- **Improved scalability** for high-traffic applications

## Configuration Methods

Shakapacker supports CDN configuration through three methods (in order of precedence):

1. **Environment Variable** (highest priority): `SHAKAPACKER_ASSET_HOST`
2. **Shakapacker Configuration File**: `asset_host` setting in `config/shakapacker.yml`
3. **Rails Configuration**: `Rails.application.config.asset_host`

## Step-by-Step Setup

### 1. Configure Your CDN

First, set up your CDN to pull assets from your application's `/packs` directory. The exact steps depend on your CDN provider, but generally you'll need to:

1. Create a CDN distribution/zone
2. Set your application's domain as the origin server
3. Configure the CDN to cache files from `/packs/*` path
4. Note your CDN URL (e.g., `https://cdn.example.com` or `https://d1234567890.cloudfront.net`)

### 2. Configure Shakapacker Asset Host

Choose one of the following methods:

#### Option A: Using Environment Variable (Recommended for Production)

Set the `SHAKAPACKER_ASSET_HOST` environment variable:

```bash
# For production deployment
export SHAKAPACKER_ASSET_HOST=https://cdn.example.com

# Or in your .env file
SHAKAPACKER_ASSET_HOST=https://cdn.example.com
```

#### Option B: Using shakapacker.yml

Add the `asset_host` setting to your `config/shakapacker.yml`:

```yaml
production:
  # ... other settings ...
  asset_host: https://cdn.example.com

  # You can also set different CDN hosts per environment
staging:
  asset_host: https://staging-cdn.example.com
```

#### Option C: Using Rails Configuration

Configure in your Rails environment file (e.g., `config/environments/production.rb`):

```ruby
Rails.application.configure do
  # ... other settings ...

  # This will be used by Shakapacker if SHAKAPACKER_ASSET_HOST
  # and asset_host in shakapacker.yml are not set
  config.action_controller.asset_host = 'https://cdn.example.com'
end
```

### 3. Compile Assets

During deployment, compile your assets as usual:

```bash
# The SHAKAPACKER_ASSET_HOST will be used during compilation
# to set the webpack publicPath
RAILS_ENV=production bundle exec rake assets:precompile
```

This ensures that:

- Webpack's `publicPath` is set to your CDN URL
- Dynamic imports and code-split chunks load from the CDN
- Asset manifest references use CDN URLs

### 4. Deploy and Sync Assets

After compilation, ensure your compiled assets in `public/packs` are accessible to your CDN:

- **Push CDN**: Upload the files to your CDN's storage
- **Pull CDN**: Deploy your application normally; the CDN will pull assets on first request

## CloudFlare Specific Setup

For CloudFlare CDN setup:

### 1. Create a CloudFlare Account and Add Your Domain

1. Sign up for CloudFlare (if you haven't already)
2. Add your domain to CloudFlare
3. Update your domain's nameservers to CloudFlare's

### 2. Configure Page Rules for Assets

Create a page rule for your assets:

1. Go to **Page Rules** in CloudFlare dashboard
2. Create a new rule for `*yourdomain.com/packs/*`
3. Set the following settings:
   - **Cache Level**: Cache Everything
   - **Edge Cache TTL**: 1 month (or your preference)
   - **Browser Cache TTL**: 1 month

### 3. Set Up CloudFlare for Assets Only (Optional)

If you want CloudFlare to only serve your assets (not your entire site):

1. Create a CNAME record: `cdn.yourdomain.com` → `yourdomain.com`
2. Set CloudFlare proxy (orange cloud) ON for this record
3. Configure Shakapacker:

```bash
export SHAKAPACKER_ASSET_HOST=https://cdn.yourdomain.com
```

### 4. Configure CloudFlare Settings

Recommended CloudFlare settings for assets:

- **SSL/TLS**: Full or Full (Strict)
- **Caching Level**: Standard or Aggressive
- **Browser Cache TTL**: Respect Existing Headers
- **Always Online**: On
- **Auto Minify**: OFF (Shakapacker already minifies)

## Verification

To verify your CDN setup is working:

### 1. Check Compiled Assets

After compilation, inspect a compiled JavaScript file:

```bash
# Look for the publicPath setting in your compiled bundles
grep -r "publicPath" public/packs/js/
```

You should see your CDN URL in the publicPath configuration.

### 2. Check Page Source

In production, view your page source and verify script tags use CDN URLs:

```html
<!-- Correct: Assets loading from CDN -->
<script src="https://cdn.example.com/packs/js/application-abc123.js"></script>

<!-- Wrong: Assets loading from relative path -->
<script src="/packs/js/application-abc123.js"></script>
```

### 3. Check Network Tab

1. Open browser DevTools
2. Go to Network tab
3. Reload the page
4. Verify JavaScript files are loaded from CDN domain

### 4. Check Dynamic Imports

If using code splitting, verify dynamic chunks load from CDN:

```javascript
// This dynamic import should load from CDN
import("./components/HeavyComponent").then((module) => {
  // Check Network tab - chunk should load from CDN
})
```

## Troubleshooting

### Assets Not Loading from CDN

**Problem**: Assets are still loading from your application domain.

**Solutions**:

1. Ensure you set `SHAKAPACKER_ASSET_HOST` **before** running `assets:precompile`
2. Clear Rails cache: `bundle exec rake tmp:cache:clear`
3. Check the manifest.json file includes CDN URLs:
   ```bash
   cat public/packs/manifest.json
   ```

### CORS Errors

**Problem**: Browser shows CORS errors when loading assets from CDN.

**Solutions**:

1. Configure your CDN to add CORS headers:
   ```
   Access-Control-Allow-Origin: *
   ```
2. Or configure for specific domain:
   ```
   Access-Control-Allow-Origin: https://yourdomain.com
   ```

### Fonts Not Loading

**Problem**: Web fonts fail to load from CDN due to CORS.

**Solutions**:

1. Ensure CDN sends proper CORS headers for font files
2. In CloudFlare, create a page rule for `*.woff2`, `*.woff`, `*.ttf` files with CORS headers
3. Consider hosting fonts separately or using base64 encoding

### Development Environment Issues

**Problem**: CDN URLs appearing in development environment.

**Solution**: Only set `SHAKAPACKER_ASSET_HOST` in production:

```ruby
# config/environments/development.rb
# Ensure asset_host is NOT set in development

# config/environments/production.rb
# Set asset_host only in production
```

## Advanced Configuration

### Using Different CDNs for Different Assets

You can use Rails asset host proc for dynamic CDN selection:

```ruby
# config/environments/production.rb
config.action_controller.asset_host = Proc.new do |source|
  if source =~ /\.(js|css)$/
    'https://js-css-cdn.example.com'
  else
    'https://images-cdn.example.com'
  end
end
```

### CDN with Integrity Hashes

When using Subresource Integrity (SRI) with CDN:

```yaml
# config/shakapacker.yml
production:
  asset_host: https://cdn.example.com
  integrity:
    enabled: true
    hash_functions: ["sha384"]
    cross_origin: "anonymous"
```

Ensure your CDN serves files with CORS headers:

```
Access-Control-Allow-Origin: *
```

### Multiple CDN Domains for Parallel Downloads

For HTTP/1.1 optimization (less relevant with HTTP/2):

```ruby
# config/environments/production.rb
config.action_controller.asset_host = Proc.new do |source|
  "https://cdn#{Digest::MD5.hexdigest(source)[0..2].to_i(16) % 4}.example.com"
end
# This creates cdn0.example.com through cdn3.example.com
```

### Cache Busting

Shakapacker automatically includes content hashes in production:

```yaml
# config/shakapacker.yml
production:
  # This is already true by default in production
  useContentHash: true
```

This ensures CDN caches are invalidated when content changes.

### Preloading Critical Assets

Use Rails helpers to preload critical assets from CDN:

```erb
<%= preload_pack_asset 'application.js' %>
<%= preload_pack_asset 'application.css' %>
```

## Security Considerations

1. **Use HTTPS**: Always use HTTPS for your CDN URL to prevent mixed content warnings
2. **Configure CSP**: Update Content Security Policy headers to allow CDN domain:
   ```ruby
   # config/initializers/content_security_policy.rb
   Rails.application.config.content_security_policy do |policy|
     policy.script_src :self, 'https://cdn.example.com'
     policy.style_src :self, 'https://cdn.example.com'
   end
   ```
3. **Use SRI**: Enable Subresource Integrity for additional security
4. **Monitor CDN**: Set up monitoring for CDN availability and performance

## Example Configuration

Here's a complete example for a production setup with CloudFlare:

```yaml
# config/shakapacker.yml
production:
  compile: false
  cache_manifest: true
  asset_host: <%= ENV.fetch('SHAKAPACKER_ASSET_HOST', 'https://cdn.example.com') %>

  # Enable integrity checking
  integrity:
    enabled: true
    hash_functions: ["sha384"]
    cross_origin: "anonymous"
```

```ruby
# config/environments/production.rb
Rails.application.configure do
  # Fallback if SHAKAPACKER_ASSET_HOST is not set
  config.action_controller.asset_host = 'https://cdn.example.com'

  # Ensure proper headers for CDN
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=31536000',
    'X-Content-Type-Options' => 'nosniff'
  }
end
```

```bash
# Deployment script
export SHAKAPACKER_ASSET_HOST=https://cdn.example.com
RAILS_ENV=production bundle exec rake assets:precompile
```

## Summary

Setting up a CDN with Shakapacker involves:

1. Configuring your CDN service
2. Setting the `SHAKAPACKER_ASSET_HOST` environment variable
3. Compiling assets with the CDN URL
4. Deploying and verifying the setup

The key is ensuring `SHAKAPACKER_ASSET_HOST` is set during asset compilation so webpack's `publicPath` is configured correctly for dynamic imports and code-split chunks.
