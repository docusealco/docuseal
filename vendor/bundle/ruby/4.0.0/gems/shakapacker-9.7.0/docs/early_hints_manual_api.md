# HTTP 103 Early Hints - Manual API Guide

> **📚 Main Documentation:** This guide covers the manual `send_pack_early_hints` API for advanced use cases. For the recommended controller-based API (`configure_pack_early_hints`, `skip_send_pack_early_hints`) and comprehensive setup instructions, see [early_hints.md](early_hints.md).

This guide focuses on **manual control** of early hints for advanced scenarios where you need to send hints before expensive controller work or customize hints per-pack in layouts.

## Automatic vs Manual API

By default, Shakapacker automatically sends early hints when `javascript_pack_tag` and `stylesheet_pack_tag` are called (after views render). The manual API allows you to:

- **Send hints earlier** - Before controller work starts, maximizing parallelism
- **Customize per-pack** - Different strategies for different packs in the same layout
- **Override automatic behavior** - When you need fine-grained control

## ⚠️ IMPORTANT: Performance Testing Required

**Early hints can improve OR hurt performance** depending on your application:

- ✅ **May help**: Large JS bundles (>500KB), slow controllers (>300ms), fast CDN
- ❌ **May hurt**: Large images as LCP (Largest Contentful Paint), small JS bundles
- ⚠️ **Test before deploying**: Measure LCP and Time to Interactive before/after enabling

**How to test:**

1. Enable early hints in production for 10% of traffic
2. Measure Core Web Vitals (LCP, FCP, TTI) for both groups
3. Only keep enabled if metrics improve

See the [Feature Testing Guide](feature_testing.md#http-103-early-hints) for testing instructions and the [main documentation](early_hints.md) for comprehensive troubleshooting.

## When to Use the Manual API

Use `send_pack_early_hints` when you need:

1. **Maximum parallelism** - Send hints BEFORE expensive controller work (database queries, API calls)
2. **Per-pack customization** - Different hint strategies for different packs in layouts
3. **Dynamic control** - Runtime decisions about which packs to hint

For most applications, use the [controller-based API](early_hints.md#controller-configuration) instead (`configure_pack_early_hints`, `skip_send_pack_early_hints`).

## Manual API Patterns

### Pattern 1: Per-Pack Customization in Layout

Customize hint handling per pack using a hash:

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <%# Mixed handling: preload application, prefetch vendor %>
    <%= stylesheet_pack_tag 'application', 'vendor',
          early_hints: { 'application' => 'preload', 'vendor' => 'prefetch' } %>
  </head>
  <body>
    <%= yield %>
    <%# Disable early hints for this tag %>
    <%= javascript_pack_tag 'application', early_hints: false %>
  </body>
</html>
```

**Options:**

- `"preload"` - High priority (default)
- `"prefetch"` - Low priority
- `false` or `"none"` - Disabled

---

### Pattern 2: Controller Override (Before Expensive Work)

Send hints manually in controller BEFORE expensive work to maximize parallelism:

```ruby
class PostsController < ApplicationController
  def show
    # Send hints BEFORE expensive work
    send_pack_early_hints({
      "application" => { js: "preload", css: "preload" },
      "admin" => { js: "prefetch", css: "none" }
    })

    # Browser now downloading assets while we do expensive work
    @post = Post.includes(:comments, :author, :tags).find(params[:id])
    @related = @post.find_related_posts(limit: 10)  # Expensive query
    # ... more work ...
  end
end
```

**Timeline:**

1. Request arrives
2. `send_pack_early_hints` called → HTTP 103 sent immediately
3. Browser starts downloading assets
4. Rails continues with expensive queries (IN PARALLEL with browser downloads)
5. View renders
6. HTTP 200 sent with full HTML
7. Assets already downloaded = faster page load

**Benefits:**

- ✅ Parallelizes browser downloads with server processing
- ✅ Can save 200-500ms on pages with slow controllers
- ✅ Most valuable for pages with expensive queries/API calls

---

### Pattern 3: View Override

Views can use `append_*_pack_tag` to add packs dynamically:

```erb
<%# app/views/posts/edit.html.erb %>
<% append_javascript_pack_tag 'admin_tools' %>

<div class="post-editor">
  <%# ... editor UI ... %>
</div>
```

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <%= stylesheet_pack_tag 'application' %>
  </head>
  <body>
    <%= yield %>  <%# View has run, admin_tools added to queue %>

    <%# Sends hints for BOTH application + admin_tools %>
    <%= javascript_pack_tag 'application' %>
  </body>
</html>
```

**How it works:**

- Views call `append_javascript_pack_tag('admin_tools')`
- Layout calls `javascript_pack_tag('application')`
- Helper combines: `['application', 'admin_tools']`
- Sends hints for ALL packs automatically

---

## Configuration

> **📚 Configuration:** See the [main documentation](early_hints.md#quick-start) for all configuration options including global settings, priority levels (preload/prefetch/none), and per-controller configuration.

---

## Duplicate Prevention

Hints are automatically prevented from being sent twice:

```ruby
# Controller
def show
  send_pack_early_hints({ "application" => { js: "preload", css: "preload" } })
  # ... expensive work ...
end
```

```erb
<%# Layout %>
<%= javascript_pack_tag 'application' %>
<%# Won't send duplicate hint - already sent in controller %>
```

**How it works:**

- Tracks which packs have sent JS hints: `@early_hints_javascript = {}`
- Tracks which packs have sent CSS hints: `@early_hints_stylesheets = {}`
- Skips sending hints for packs already sent

---

## When to Use Each Pattern

### Pattern 1 (Per-Pack) - Best for:

- Mixed vendor bundles (preload critical, prefetch non-critical)
- Different handling for different packs
- Layout-specific optimizations

### Pattern 2 (Controller) - Best for:

- Slow controllers with expensive queries (>300ms)
- Large JS bundles (>500KB)
- APIs calls in controller
- Maximum parallelism needed

### Pattern 3 (View Override) - Best for:

- Admin sections with extra packs
- Feature flags determining packs
- Page-specific bundles

---

## Full Example: Mixed Patterns

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    # Fast controller, automatic hints work fine (Pattern 1)
  end

  def show
    # Slow controller, send hints early for parallelism (Pattern 2)
    send_pack_early_hints({
      "application" => { js: "preload", css: "preload" }
    })

    # Expensive work happens in parallel with browser downloads
    @post = Post.includes(:comments, :author).find(params[:id])
  end
end
```

```erb
<%# app/views/posts/show.html.erb %>
<% if current_user&.admin? %>
  <%# Pattern 3: Dynamic pack loading based on user role %>
  <% append_javascript_pack_tag 'admin_tools' %>
<% end %>
```

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <%= stylesheet_pack_tag 'application' %>
  </head>
  <body>
    <%= yield %>

    <%# Sends hints for application + admin_tools (if appended) %>
    <%# Won't duplicate hints already sent in controller %>
    <%= javascript_pack_tag 'application' %>
  </body>
</html>
```

---

## Preloading Non-Pack Assets (Images, Videos, Fonts)

**Shakapacker's early hints are for pack assets (JS/CSS bundles).** For non-pack assets like hero images, videos, and fonts, you have two options.

> **Note:** The [main documentation](early_hints.md#4-preloading-hero-images-and-videos) covers using Rails' built-in `preload_link_tag` for images and videos, which is simpler than the manual approach below.

### Option 1: Manual Early Hints (For LCP/Critical Assets)

**IMPORTANT:** Browsers only process the FIRST HTTP 103 response. If you need both pack assets AND images/videos in early hints, you must send them together in ONE call.

```ruby
class PostsController < ApplicationController
  before_action :send_critical_early_hints, only: [:show]

  private

  def send_critical_early_hints
    # Build all early hints in ONE call (packs + images)
    links = []

    # Pack assets (using Shakapacker manifest)
    js_path = "/packs/#{Shakapacker.manifest.lookup!('application.js')}"
    css_path = "/packs/#{Shakapacker.manifest.lookup!('application.css')}"
    links << "<#{js_path}>; rel=preload; as=script"
    links << "<#{css_path}>; rel=preload; as=style"

    # Critical images (for LCP - Largest Contentful Paint)
    links << "<#{view_context.asset_path('hero.jpg')}>; rel=preload; as=image"

    # Send ONE HTTP 103 response with all hints
    request.send_early_hints("Link" => links.join(", "))
  end

  def show
    # Early hints already sent, browser downloading assets in parallel
    @post = Post.find(params[:id])
  end
end
```

**When to use:**

- Pages with hero images affecting LCP (Largest Contentful Paint)
- Videos that must load quickly
- Critical fonts not in pack bundles

### Option 2: HTML Preload Links (Simpler, No Early Hints)

Use Rails' `preload_link_tag` to add `<link rel="preload">` in the HTML:

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <%# Shakapacker sends early hints for packs %>
    <%= stylesheet_pack_tag 'application' %>

    <%# Preload link in HTML (no HTTP 103, but still speeds up loading) %>
    <%= preload_link_tag asset_path('hero.jpg'), as: 'image' %>
  </head>
  <body>
    <%= yield %>
    <%= javascript_pack_tag 'application' %>
  </body>
</html>
```

**When to use:**

- Images that don't affect LCP
- Less critical assets
- Simpler implementation preferred

**Note:** `preload_link_tag` only adds HTML `<link>` tags - it does NOT send HTTP 103 Early Hints.

---

## Requirements & Limitations

> **📚 Full Requirements:** See the [main documentation](early_hints.md#requirements) for complete browser and server requirements. This section covers limitations specific to the manual API.

**IMPORTANT:** Understand these limitations when using the manual API:

### Architecture: Proxy Required for HTTP/2

**Standard production architecture for Early Hints:**

```
Browser (HTTP/2)
    ↓
Proxy (Thruster ✅, nginx ✅, Cloudflare ✅)
    ├─ Receives HTTP/2
    ├─ Translates to HTTP/1.1
    ↓
Puma (HTTP/1.1 with --early-hints flag)
    ├─ Sends HTTP/1.1 103 Early Hints ✅
    ├─ Sends HTTP/1.1 200 OK
    ↓
Proxy
    ├─ Translates to HTTP/2
    ↓
Browser (HTTP/2 103) ✅
```

**Key insights:**

- Puma always runs HTTP/1.1 and requires `--early-hints` flag
- The proxy handles HTTP/2 for external clients
- **NOT all proxies support early hints** (Control Plane ❌, AWS ALB ❌)

### Puma Limitation: HTTP/1.1 Only

**Puma ONLY supports HTTP/1.1 Early Hints** (not HTTP/2). This is a Rack/Puma limitation, and **there are no plans to add HTTP/2 support to Puma**.

- ✅ **Works**: Puma 5+ with HTTP/1.1
- ❌ **Doesn't work**: Puma with HTTP/2 (h2)
- ✅ **Solution**: Use a proxy in front of Puma (Thruster, nginx, etc.)

**This is the expected architecture** - there's always something in front of Puma to handle HTTP/2 translation in production.

### Browser Behavior

**Browsers only process the FIRST `HTTP/1.1 103` response.**

- Shakapacker sends ONE 103 response with ALL hints (JS + CSS combined)
- Subsequent 103 responses are ignored by browsers
- This is by design per the HTTP 103 spec

### Testing Locally

> **📚 Full Testing Guide:** See the [Feature Testing Guide](feature_testing.md#http-103-early-hints) for comprehensive testing instructions with browser DevTools and curl.

**Step 1: Enable early hints in your test environment**

```yaml
# config/shakapacker.yml
development: # or production
  early_hints:
    enabled: true
    debug: true # Shows hints in HTML comments
```

**Step 2: Start Rails with Puma's `--early-hints` flag**

```bash
# Option 1: Test in development (if enabled above)
bundle exec puma --early-hints

# Option 2: Test in production mode locally (more realistic)
RAILS_ENV=production bundle exec rake assets:precompile  # Compile assets first
RAILS_ENV=production bundle exec puma --early-hints -e production
```

**Step 3: Test with curl**

```bash
# Use HTTP/1.1 (NOT HTTP/2)
curl -v http://localhost:3000/

# Look for this in output:
< HTTP/1.1 103 Early Hints
< link: </packs/application-abc123.js>; rel=preload; as=script
< link: </packs/application-abc123.css>; rel=preload; as=style
<
< HTTP/1.1 200 OK
```

**Important notes:**

- Use `http://` (not `https://`) for local testing
- Puma dev mode uses HTTP/1.1 (not HTTP/2)
- Test in production mode for realistic asset paths with content hashes
- Early hints must be `enabled: true` for the environment you're testing

### Production Setup

> **📚 Production Setup:** See the [main documentation](early_hints.md#requirements) for complete production setup instructions including Puma configuration, proxy setup (Thruster, nginx, Cloudflare), and troubleshooting proxy issues.

**Quick checklist:**

- Puma 5+ with `--early-hints` flag (REQUIRED)
- HTTP/2-capable proxy (Thruster ✅, nginx ✅, Cloudflare ✅, Control Plane ❌, AWS ALB ❌)
- Rails 5.2+

---

## Troubleshooting

> **📚 Complete Troubleshooting:** See the [main documentation](early_hints.md#troubleshooting) for comprehensive troubleshooting including debug mode, proxy configuration, and performance optimization.

Quick debugging steps:

1. Enable `debug: true` in shakapacker.yml to see hints in HTML comments
2. Verify Puma started with `--early-hints` flag
3. Test with `curl -v http://localhost:3000/` to see if Puma sends 103 responses
4. Check if your proxy strips 103 responses (Control Plane ❌, AWS ALB ❌)

### Reference

- [Main Early Hints Documentation](early_hints.md)
- [Feature Testing Guide](feature_testing.md#http-103-early-hints)
- [Rails 103 Early Hints Analysis](https://island94.org/2025/10/rails-103-early-hints-could-be-better-maybe-doesn-t-matter)
