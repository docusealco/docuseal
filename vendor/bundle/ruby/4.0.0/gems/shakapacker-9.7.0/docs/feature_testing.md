# Feature Testing Guide

This guide shows how to manually verify that Shakapacker features are working correctly in your application.

## Table of Contents

- [HTTP 103 Early Hints](#http-103-early-hints)
- [Asset Compilation](#asset-compilation)
- [Code Splitting](#code-splitting)
- [Subresource Integrity (SRI)](#subresource-integrity-sri)
- [Source Maps](#source-maps)
- [Development Server](#development-server)

## HTTP 103 Early Hints

### Prerequisites

- Rails 5.2+
- HTTP/2-capable server (Puma 5+ recommended)
- Modern browser (Chrome/Edge/Firefox 103+, Safari 16.4+)

### ⚠️ Development Mode Limitations

**Early hints require HTTP/2 and will NOT work in standard Rails development mode**, which uses HTTP/1.1 by default.

**Why localhost testing doesn't work:**

- Early hints require HTTP/2
- HTTP/2 requires HTTPS/TLS (not `http://`)
- Plain `http://localhost` uses HTTP/1.1
- Early hints are silently ignored on HTTP/1.1

**Debug Mode:** Enable `debug: true` in config to see HTML comments showing what hints were sent (or why they weren't):

```yaml
# config/shakapacker.yml
development:
  early_hints:
    enabled: true
    debug: true # Outputs debug info as HTML comments
```

**Testing recommendation:** Use Method 1 (Browser DevTools) or Method 2 (curl) on production/staging environments with HTTPS enabled. You should see BOTH `HTTP/2 103` (early hints) and `HTTP/2 200` (final response).

### Method 1: Browser DevTools (Recommended)

1. **Enable early hints in config:**

   ```yaml
   # config/shakapacker.yml
   production:
     early_hints:
       enabled: true
   ```

2. **Open Chrome DevTools** (F12 or Cmd+Option+I)

3. **Go to Network tab** and reload your page

4. **Look for the initial document request** (usually first row)

5. **Check the Status column** - you should see:
   - `103 Early Hints` (shown briefly before the final response)
   - Followed by `200 OK` for the final HTML

6. **Verify Link headers:**
   - Click on the document request
   - Go to the "Headers" tab
   - Scroll to "Response Headers" section
   - Look for `Link:` headers with `rel=preload` or `rel=prefetch`

**Expected output:**

```
Link: </packs/application-abc123.js>; rel=preload; as=script; crossorigin="anonymous"
Link: </packs/application-xyz789.css>; rel=preload; as=style; crossorigin="anonymous"
```

### Method 2: curl (Command Line)

**Test early hints with curl (requires HTTPS/HTTP2):**

```bash
# Production/staging with HTTPS
curl -v --http2 https://your-app.com 2>&1 | grep -A5 "< HTTP"

# Look for:
# < HTTP/2 103
# < link: </packs/...>; rel=preload
# < HTTP/2 200
```

**⚠️ Local testing limitations:**

```bash
# This will NOT show early hints (returns HTTP/1.1):
RAILS_ENV=production bundle exec rails server
curl -v --http2 http://localhost:3000 2>&1 | grep -A5 "< HTTP"
# Output: < HTTP/1.1 200 OK (no 103 status)

# Why: Puma requires SSL certificates for HTTP/2
# Early hints need HTTP/2, which needs HTTPS
```

**Expected output:**

```
< HTTP/2 103
< link: </packs/application-abc123.js>; rel=preload; as=script; crossorigin="anonymous"
< link: </packs/application-xyz789.css>; rel=preload; as=style; crossorigin="anonymous"
<
< HTTP/2 200
< content-type: text/html; charset=utf-8
```

### Method 3: Check HTML Source

Early hints don't appear in HTML source (they're sent as HTTP headers before HTML). However, you can verify the assets exist:

```html
<!-- View page source and look for these tags in <head> or before </body> -->
<script src="/packs/application-abc123.js"></script>
<link rel="stylesheet" href="/packs/application-xyz789.css" />
```

The asset filenames in early hints should match those in your HTML.

### Troubleshooting Early Hints

**Not seeing 103 status?**

1. **Enable debug mode to see what's happening:**

   ```yaml
   # config/shakapacker.yml
   production: # or development
     early_hints:
       enabled: true
       debug: true # Shows debug info as HTML comments
   ```

   View page source and look for `<!-- Shakapacker Early Hints Debug -->` comments showing what hints were sent or why they were skipped.

2. **Reverse proxies and CDNs often strip 103 responses:**

   **Most common cause**: If debug mode shows hints are being sent but you don't see `HTTP/2 103` in curl or DevTools, your reverse proxy or CDN is likely stripping the 103 status code before it reaches the client.

   Common culprits:
   - Control Plane (cpln.app)
   - Some Cloudflare configurations
   - nginx without explicit early hints support
   - AWS ALB/ELB
   - Other load balancers and proxies

   **How to fix proxy stripping:**

   **nginx** - Enable early hints support:

   ```nginx
   # nginx.conf
   http {
     # Enable HTTP/2
     server {
       listen 443 ssl http2;

       # Pass through early hints (nginx 1.13+)
       proxy_pass_header Link;

       location / {
         proxy_pass http://rails_backend;
         proxy_http_version 1.1;
       }
     }
   }
   ```

   **Cloudflare** - Early hints are supported but must be enabled:
   - Go to Speed > Optimization in your Cloudflare dashboard
   - Enable "Early Hints"
   - Note: Only available on paid plans (Pro, Business, Enterprise)

   **AWS ALB/ELB** - Does NOT support HTTP/2 103:
   - AWS load balancers strip 103 responses
   - **Workaround**: Deploy without ALB/ELB, or accept Link headers in 200 response
   - Alternative: Use CloudFront with origin that supports 103

   **Control Plane (cpln.app)** - Appears to strip 103:
   - Control Plane supports HTTP/2 by default but early hints (103) don't appear to pass through
   - No documented configuration option for early hints passthrough
   - **Contact Control Plane support** if you need early hints support for your application
   - **Workaround**: Early hints will work server-side but won't be visible to clients
   - Link headers may still be included in 200 response

   **General workaround when proxy strips 103:**
   - Rails still sends Link headers in the 200 response
   - Browsers can use these for next-page prefetch (not early hints benefit)
   - Consider if early hints are worth the complexity for your setup
   - Use debug mode to verify Rails is sending hints correctly

3. **Check server supports HTTP/2 and early hints:**

   ```bash
   # Puma version (need 5+)
   bundle exec puma --version
   ```

4. **Verify config is enabled:**

   ```bash
   # In Rails console
   Shakapacker.config.early_hints
   # Should return: { enabled: true, css: "preload", js: "preload", debug: false }
   ```

5. **Check Rails log for debug messages:**

   ```bash
   tail -f log/production.log | grep -i "early hints"
   ```

6. **Verify your server uses HTTP/2:**
   ```bash
   curl -I --http2 https://your-app.com | grep -i "HTTP/2"
   ```

## Asset Compilation

### Verify Assets Compile Successfully

**Check manifest.json:**

```bash
# Development
cat public/packs/manifest.json | jq .

# Production (after precompile)
cat public/packs/manifest.json | jq '.entrypoints'
```

**Expected output:**

```json
{
  "entrypoints": {
    "application": {
      "assets": {
        "js": [
          "/packs/vendors~application-abc123.chunk.js",
          "/packs/application-xyz789.js"
        ],
        "css": ["/packs/application-abc123.chunk.css"]
      }
    }
  }
}
```

**Verify assets exist on disk:**

```bash
ls -lh public/packs/
# Should see .js, .css, .map files with hashed names
```

### Check HTML References

**View page source and verify pack tags:**

```html
<!-- Should see hashed filenames -->
<link rel="stylesheet" href="/packs/application-abc123.css" />
<script src="/packs/application-xyz789.js"></script>
```

## Code Splitting

### Verify Chunks Are Created

**Check manifest.json for chunks:**

```bash
cat public/packs/manifest.json | jq '.entrypoints.application.assets.js'
```

**Expected output (with code splitting):**

```json
[
  "/packs/vendors~application-abc123.chunk.js", // Vendor chunk
  "/packs/application-xyz789.js" // Main chunk
]
```

**View Network tab in DevTools:**

- Should see multiple `.chunk.js` files loading
- Chunks load in order (vendors first, then application code)

## Subresource Integrity (SRI)

### Verify Integrity Attributes

**Enable SRI in config:**

```yaml
# config/shakapacker.yml
production:
  integrity:
    enabled: true
```

**Check manifest.json for integrity hashes:**

```bash
cat public/packs/manifest.json | jq '.application.js'
```

**Expected output:**

```json
{
  "src": "/packs/application-abc123.js",
  "integrity": "sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC"
}
```

**Check HTML for integrity attribute:**

```html
<!-- View page source -->
<script
  src="/packs/application-abc123.js"
  integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC"
  crossorigin="anonymous"
></script>
```

### Verify SRI Works

**Break the integrity (for testing):**

1. Edit `public/packs/application-xyz789.js` (add a space)
2. Reload page
3. **Expected:** Browser console shows SRI error:
   ```
   Failed to find a valid digest in the 'integrity' attribute
   ```

## Source Maps

### Verify Source Maps Generate

**Check for .map files:**

```bash
ls -lh public/packs/*.map
# Should see .js.map and .css.map files
```

**Check HTML references source maps:**

```bash
curl http://localhost:3000/packs/application-xyz789.js | tail -5
```

**Expected output:**

```javascript
//# sourceMappingURL=application-xyz789.js.map
```

### Verify Source Maps Work in DevTools

1. **Open DevTools** → Sources tab
2. **Find your source files** under `webpack://` or `src/`
3. **Set a breakpoint** in your original source code
4. **Trigger the code** - debugger should stop at your source, not compiled output

## Development Server

### Verify Dev Server Running

**Check server status:**

```bash
# Start dev server
./bin/shakapacker-dev-server

# In another terminal, check it's running
curl http://localhost:3035
# Should return: "Shakapacker is running"
```

**Check Rails connects to dev server:**

```bash
# Start Rails
./bin/dev  # or rails server

# Check Rails log for:
[Shakapacker] Compiling...
[Shakapacker] Compiled all packs in /app/public/packs
```

**Verify hot reloading:**

1. Edit a JavaScript file in `app/javascript/`
2. Save the file
3. Browser should automatically reload (if HMR configured)
4. Or check terminal shows recompile message

### Troubleshooting Dev Server

**Connection refused?**

```bash
# Check dev_server.yml
cat config/shakapacker.yml | grep -A10 "dev_server"

# Verify settings:
# host: localhost
# port: 3035
# https: false
```

**Test connection manually:**

```bash
curl http://localhost:3035/packs/application.js
# Should return JavaScript code (not 404)
```

## Testing Checklist

Use this checklist to verify a complete Shakapacker setup:

- [ ] **Assets compile:** `bundle exec rake assets:precompile` succeeds
- [ ] **Manifest exists:** `public/packs/manifest.json` contains entrypoints
- [ ] **Assets load:** Page loads without 404s for pack files
- [ ] **Code splitting works:** Multiple chunks load in Network tab
- [ ] **Source maps work:** Can debug original source in DevTools
- [ ] **Dev server runs:** `./bin/shakapacker-dev-server` starts successfully
- [ ] **SRI enabled (if configured):** HTML contains `integrity` attributes
- [ ] **Early hints work (if configured):** DevTools shows 103 status

## Common Issues

### Assets Return 404

**Check manifest:**

```bash
cat public/packs/manifest.json | jq .
```

**Recompile:**

```bash
bundle exec rake assets:precompile
```

### Old Assets Cached

**Clear public/packs:**

```bash
rm -rf public/packs
bundle exec rake assets:precompile
```

### Dev Server Won't Start

**Check port not in use:**

```bash
lsof -i :3035
# Kill process if needed
kill -9 <PID>
```

**Check dev_server config:**

```bash
cat config/shakapacker.yml | grep -A10 dev_server
```

## Additional Resources

- [Configuration Guide](configuration.md)
- [Early Hints Guide](early_hints.md)
- [Subresource Integrity Guide](subresource_integrity.md)
- [Troubleshooting Guide](troubleshooting.md)
