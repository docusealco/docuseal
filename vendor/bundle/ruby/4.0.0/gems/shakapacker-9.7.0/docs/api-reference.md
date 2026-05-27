# Shakapacker API Reference

This document provides a comprehensive reference for Shakapacker's public Ruby API. For JavaScript/webpack configuration, see [Webpack Configuration](./webpack-configuration.md).

## Table of Contents

- [Overview](#overview)
- [Main Module: Shakapacker](#main-module-shakapacker)
- [Configuration API](#configuration-api)
- [View Helpers](#view-helpers)
- [Manifest API](#manifest-api)
- [Dev Server API](#dev-server-api)
- [Compiler API](#compiler-api)
- [Advanced Usage](#advanced-usage)

## Overview

Shakapacker provides a Ruby API for integrating webpack/rspack with Rails applications. The API is divided into several key areas:

- **Configuration**: Access to `config/shakapacker.yml` settings
- **View Helpers**: Rails helpers for rendering script/link tags
- **Manifest**: Asset lookup and resolution
- **Compilation**: Programmatic asset compilation
- **Dev Server**: Development server status and management

### What's Public API?

Methods and classes marked with `@api public` in the source code are considered stable public API. Other methods may change between minor versions.

## Main Module: Shakapacker

The `Shakapacker` module provides singleton-style access to all major functionality.

### Configuration Access

```ruby
# Get the configuration object
Shakapacker.config
# => #<Shakapacker::Configuration>

# Access configuration values
Shakapacker.config.source_path
# => #<Pathname:/path/to/app/javascript>

Shakapacker.config.public_output_path
# => "packs"
```

### Compilation

```ruby
# Compile all packs
Shakapacker.compile
# => true

# Check if compilation is needed
Shakapacker.compiler.stale?
# => false

# Get compiler output
Shakapacker.compiler.compile
```

### Manifest Lookup

```ruby
# Look up compiled asset path
Shakapacker.manifest.lookup("application.js")
# => "/packs/application-abc123.js"

# Look up with error if not found
Shakapacker.manifest.lookup!("application.js")
# => "/packs/application-abc123.js" (or raises Shakapacker::Manifest::MissingEntryError)
```

### Dev Server Status

```ruby
# Check if dev server is running
Shakapacker.dev_server.running?
# => true

# Get dev server host
Shakapacker.dev_server.host
# => "localhost"

# Get dev server port
Shakapacker.dev_server.port
# => 3035
```

### Environment Management

```ruby
# Get current environment
Shakapacker.env
# => #<ActiveSupport::StringInquirer "development">

# Temporarily use different NODE_ENV
Shakapacker.with_node_env("production") do
  Shakapacker.compile
end
```

### Logging

```ruby
# Access logger
Shakapacker.logger
# => #<Logger>

# Redirect to STDOUT temporarily
Shakapacker.ensure_log_goes_to_stdout do
  Shakapacker.compile
end
```

## Configuration API

The `Shakapacker::Configuration` class provides access to all settings from `config/shakapacker.yml`.

### Accessing Configuration Data

```ruby
config = Shakapacker.config

# Get raw configuration hash (public API as of v9.1.0)
config.data
# => { "source_path" => "app/javascript", ... }

# Access specific values
config.data["source_path"]
# => "app/javascript"
```

**See Also:** [Configuration Guide](./configuration.md) for all available options.

### Path Configuration

```ruby
# Source paths
config.source_path          # => #<Pathname:/app/app/javascript>
config.source_entry_path    # => #<Pathname:/app/app/javascript/packs>
config.additional_paths     # => [#<Pathname:/app/app/assets>, ...]

# Output paths
config.public_path          # => #<Pathname:/app/public>
config.public_output_path   # => "packs"
config.public_manifest_path # => #<Pathname:/app/public/packs/manifest.json>
```

### Bundler Detection

```ruby
# Check which bundler is configured
config.webpack?   # => true
config.rspack?    # => false
config.bundler    # => "webpack"

# Get bundler config path
config.assets_bundler_config_path
# => #<Pathname:/app/config/webpack/webpack.config.js>
```

### Compilation Settings

```ruby
config.compile?              # => true (auto-compile enabled?)
config.cache_manifest?       # => false
config.extract_css?          # => false (use MiniCssExtractPlugin?)
config.nested_entries?       # => false
```

### Dev Server Configuration

```ruby
dev_server = config.dev_server
dev_server["host"]           # => "localhost"
dev_server["port"]           # => 3035
dev_server["hmr"]            # => true
dev_server["https"]          # => false
```

## View Helpers

Shakapacker provides Rails view helpers in the `Shakapacker::Helper` module, automatically included in ActionView.

### JavaScript Pack Tag

```ruby
# Basic usage
<%= javascript_pack_tag 'application' %>
# => <script src="/packs/application-abc123.js" defer></script>

# Multiple packs (handles chunk deduplication)
<%= javascript_pack_tag 'calendar', 'map' %>

# Custom attributes
<%= javascript_pack_tag 'application', 'data-turbo-track': 'reload' %>

# Async loading
<%= javascript_pack_tag 'application', async: true %>

# Disable defer
<%= javascript_pack_tag 'application', defer: false %>

# Early hints configuration
<%= javascript_pack_tag 'application', early_hints: 'preload' %>
<%= javascript_pack_tag 'application', early_hints: false %>
```

**Important:** Call `javascript_pack_tag` only once per page to avoid duplicate chunks.

### Stylesheet Pack Tag

```ruby
# Basic usage
<%= stylesheet_pack_tag 'application' %>
# => <link rel="stylesheet" href="/packs/application-abc123.css">

# Multiple packs with attributes
<%= stylesheet_pack_tag 'application', 'calendar', media: 'screen' %>

# Early hints
<%= stylesheet_pack_tag 'application', early_hints: 'preload' %>
```

### Dynamic Pack Loading

```ruby
# In view or partial - queue packs
<% append_javascript_pack_tag 'calendar' %>
<% append_stylesheet_pack_tag 'calendar' %>

# Prepend to queue
<% prepend_javascript_pack_tag 'critical' %>

# In layout - render all queued packs
<%= javascript_pack_tag 'application' %>
<%= stylesheet_pack_tag 'application' %>
```

### Asset Helpers

```ruby
# Get pack path
<%= asset_pack_path 'logo.svg' %>
# => "/packs/logo-abc123.svg"

# Get pack URL
<%= asset_pack_url 'logo.svg' %>
# => "https://cdn.example.com/packs/logo-abc123.svg"

# Image pack tag
<%= image_pack_tag 'logo.png', size: '16x10', alt: 'Logo' %>
# => <img src="/packs/logo-abc123.png" width="16" height="10" alt="Logo">

# With srcset
<%= image_pack_tag 'photo.png', srcset: { 'photo-2x.png' => '2x' } %>

# Favicon
<%= favicon_pack_tag 'icon.png', rel: 'apple-touch-icon' %>

# Preload asset
<%= preload_pack_asset 'fonts/custom.woff2' %>
```

## Manifest API

The `Shakapacker::Manifest` class handles asset lookup from the compiled manifest.

### Basic Lookup

```ruby
manifest = Shakapacker.manifest

# Look up an asset (returns nil if not found)
manifest.lookup("application.js")
# => "/packs/application-abc123.js"

# Look up with error on missing
manifest.lookup!("application.js")
# => "/packs/application-abc123.js" (raises if missing)
```

### Lookup with Type

```ruby
# Lookup stylesheets
manifest.lookup("application.css")
# => "/packs/application-abc123.css"

# Lookup images
manifest.lookup("logo.svg")
# => "/packs/static/logo-abc123.svg"
```

### Full Manifest Access

```ruby
# Get all entries
manifest.data
# => { "application.js" => "/packs/application-abc123.js", ... }

# Refresh manifest from disk
manifest.refresh
```

## Dev Server API

The `Shakapacker::DevServer` class provides status and configuration for the development server.

### Status Checking

```ruby
dev_server = Shakapacker.dev_server

# Check if running
dev_server.running?
# => true

# Get full status URL
dev_server.status_url
# => "http://localhost:3035"
```

### Configuration

```ruby
dev_server.host
# => "localhost"

dev_server.port
# => 3035

dev_server.https?
# => false

dev_server.hmr?
# => true
```

### Proxying

```ruby
# Get asset URL (uses dev server if running, otherwise public path)
dev_server.asset_url("application.js")
# => "http://localhost:3035/packs/application.js" (or "/packs/application.js")
```

## Compiler API

The `Shakapacker::Compiler` class handles compilation of webpack/rspack assets.

### Compilation

```ruby
compiler = Shakapacker.compiler

# Compile all packs
compiler.compile
# => true

# Check if compilation needed
compiler.stale?
# => false

# Get last compilation time
compiler.last_compilation_digest
# => "abc123..."
```

### Configuration

```ruby
# Get watched paths
compiler.watched_paths
# => [#<Pathname:/app/app/javascript>, ...]

# Get config files
compiler.config_files
# => [#<Pathname:/app/config/webpack/webpack.config.js>, ...]
```

## Advanced Usage

### Multiple Shakapacker Instances

For advanced scenarios like Rails engines with separate webpack configs:

```ruby
# Create custom instance
custom_instance = Shakapacker::Instance.new(
  root_path: Rails.root,
  config_path: Rails.root.join("config/custom_shakapacker.yml")
)

# Use in view helper
def current_shakapacker_instance
  @custom_instance ||= Shakapacker::Instance.new(...)
end
```

### Testing

```ruby
# In tests, you can stub the instance
RSpec.describe "my feature" do
  let(:mock_manifest) { instance_double(Shakapacker::Manifest) }
  let(:mock_instance) { instance_double(Shakapacker::Instance, manifest: mock_manifest) }

  before do
    allow(Shakapacker).to receive(:instance).and_return(mock_instance)
  end
end
```

### Programmatic Configuration Access

```ruby
# Access raw configuration for custom tooling
config_data = Shakapacker.config.data

# Use in custom rake task
namespace :assets do
  task :analyze do
    config = Shakapacker.config
    puts "Source: #{config.source_path}"
    puts "Output: #{config.public_output_path}"
    puts "Bundler: #{config.bundler}"
  end
end
```

### Custom Webpack Configuration

Access Shakapacker config from your webpack config:

```javascript
// config/webpack/webpack.config.js
const { generateWebpackConfig } = require("shakapacker")

// The shakapacker.yml is automatically loaded
const config = generateWebpackConfig()

console.log(config.output.path) // Uses public_output_path from shakapacker.yml
```

## Environment Variables

Shakapacker respects these environment variables:

| Variable                     | Purpose                       | Example                   |
| ---------------------------- | ----------------------------- | ------------------------- |
| `SHAKAPACKER_CONFIG`         | Custom config file path       | `/custom/shakapacker.yml` |
| `SHAKAPACKER_PRECOMPILE`     | Enable/disable precompilation | `false`                   |
| `SHAKAPACKER_ASSET_HOST`     | CDN hostname                  | `https://cdn.example.com` |
| `SHAKAPACKER_ASSETS_BUNDLER` | Override bundler selection    | `rspack`                  |
| `RAILS_ENV`                  | Rails environment             | `production`              |
| `NODE_ENV`                   | Node environment              | `production`              |

## Error Handling

```ruby
# Manifest lookup errors
begin
  path = Shakapacker.manifest.lookup!("missing.js")
rescue Shakapacker::Manifest::MissingEntryError => e
  Rails.logger.error "Missing pack: #{e.message}"
end

# Compilation errors
begin
  Shakapacker.compiler.compile
rescue Shakapacker::Compiler::CompilationError => e
  Rails.logger.error "Compilation failed: #{e.message}"
end

# Configuration errors
begin
  config = Shakapacker::Configuration.new(...)
rescue Shakapacker::Configuration::InvalidConfigurationError => e
  Rails.logger.error "Invalid config: #{e.message}"
end
```

## Deprecations

Shakapacker follows semantic versioning. Deprecated methods will:

1. Issue warnings in the current major version
2. Be removed in the next major version

Check the [CHANGELOG](../CHANGELOG.md) for deprecation notices.

## See Also

- [Configuration Guide](./configuration.md) - All `shakapacker.yml` options
- [View Helpers](../README.md#view-helpers) - Detailed view helper usage
- [Webpack Configuration](../README.md#webpack-configuration) - JavaScript API
- [TypeScript](./typescript.md) - Type definitions for Shakapacker
- [Troubleshooting](./troubleshooting.md) - Common issues

## Generating Full API Documentation

For complete API documentation with all methods and parameters:

```bash
# Using YARD (recommended)
gem install yard
yard doc
yard server  # View at http://localhost:8808

# Using RDoc
rdoc lib/
open doc/index.html
```

The generated documentation includes all public and private methods with detailed parameter descriptions.
