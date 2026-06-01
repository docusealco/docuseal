# Deployment

Shakapacker hooks up a new `shakapacker:compile` task to `assets:precompile`, which gets run whenever you run `assets:precompile`.
If you are not using Sprockets `shakapacker:compile` is automatically aliased to `assets:precompile`.

**📖 For configuration options, see the [Configuration Guide](./configuration.md)**

## Precompile Hook

Shakapacker supports running a custom command before webpack compilation via the `precompile_hook` configuration option. This is useful for dynamically generating entry points (e.g., for React on Rails) or performing other preparatory tasks.

**Note:** The precompile hook runs in both development and production environments. For complete documentation, see the [Precompile Hook Guide](precompile_hook.md).

Quick example for production deployment:

```yaml
# config/shakapacker.yml
production:
  precompile_hook: "bin/rake react_on_rails:generate_packs"
```

This ensures your dynamic entry points are generated before `assets:precompile` runs.

## Heroku

In order for your Shakapacker app to run on Heroku, you'll need to do a bit of configuration before hand.

```bash
heroku create my-shakapacker-heroku-app
heroku addons:create heroku-postgresql:hobby-dev
heroku buildpacks:add heroku/nodejs
heroku buildpacks:add heroku/ruby
git push heroku master
```

We're essentially doing the following here:

- Creating an app on Heroku
- Creating a Postgres database for the app (this is assuming that you're using Heroku Postgres for your app)
- Adding the Heroku NodeJS and Ruby buildpacks for your app. This allows the `npm` or `yarn` executables to properly function when compiling your app - as well as Ruby.
- Pushing your code to Heroku and kicking off the deployment

Your production build process is responsible for installing your JavaScript dependencies before `rake assets:precompile`. For example, if you are on Heroku, the `heroku/nodejs` buildpack must run **prior** to the `heroku/ruby` buildpack for precompilation to run successfully.

### Custom Rails Environments (e.g., staging)

**Key distinction:**

- **RAILS_ENV** is used to look up configuration in `config/shakapacker.yml`
- **NODE_ENV** is used by your `webpack.config.js` (or `rspack.config.js`) for build optimizations

**Good news:** As of this version, `bin/shakapacker` automatically sets `NODE_ENV=production` for custom environments like staging:

```bash
# NODE_ENV automatically set to 'production' for staging
RAILS_ENV=staging bin/shakapacker

# Also works with rake task
RAILS_ENV=staging bundle exec rake assets:precompile
```

**How it works:**

- `RAILS_ENV=development` → `NODE_ENV=development`
- `RAILS_ENV=test` → `NODE_ENV=test`
- `RAILS_ENV=production` → `NODE_ENV=production`
- Any other custom env → `NODE_ENV=production`

**Configuration fallback:**

You don't need to add custom environments to your `shakapacker.yml`. Shakapacker automatically falls back to production-like defaults:

1. First, it looks for the environment you're deploying to (e.g., `staging`)
2. If not found, it falls back to `production` configuration

This means staging environments automatically use production settings (compile: false, cache_manifest: true, etc.).

**Optional: Staging-specific configuration**

If you want different settings for staging, explicitly add a `staging` section:

```yaml
staging:
  <<: *default
  compile: false
  cache_manifest: true
  # Staging-specific overrides (e.g., different output path)
  public_output_path: packs-staging
```

## Nginx

Shakapacker doesn't serve anything in production. You’re expected to configure your web server to serve files in public/ directly.

Some servers support sending precompressed versions of files when they're available. For example, nginx offers a `gzip_static` directive that serves files with the `.gz` extension to supported clients. With an optional module, nginx can also serve Brotli compressed files with the `.br` extension (see below for installation and configuration instructions).

Here's a sample nginx site config for a Rails app using Shakapacker:

```nginx
upstream app {
  # server unix:///path/to/app/tmp/puma.sock;
}

server {
  listen 80;
  server_name www.example.com;
  root /path/to/app/public;

  location @app {
    proxy_pass http://app;
    proxy_redirect off;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location / {
    try_files $uri @app;
  }

  location = /favicon.ico { access_log off; log_not_found off; }
  location = /robots.txt  { access_log off; log_not_found off; }

  location ~ /\.(?!well-known).* {
    deny all;
  }

  location ~ ^/(assets|packs)/ {
    gzip_static on;
    brotli_static on; # Optional, see below
    expires max;
    add_header Cache-Control public;
  }
}
```

### Installing the ngx_brotli module

If you want to serve Brotli compressed files with nginx, you will need to install the `nginx_brotli` module. Installation instructions from source can be found in the official [google/ngx_brotli](https://github.com/google/ngx_brotli) git repository. Alternatively, depending on your platform, the module might be available via a pre-compiled package.

Once installed, you need to load the module. As we want to serve the pre-compressed files, we only need the static module. Add the following line to your `nginx.conf` file and reload nginx:

```
load_module modules/ngx_http_brotli_static_module.so;
```

Now, you can set `brotli_static on;` in your nginx site config, as per the config in the last section above.

## CDN

Shakapacker supports serving JavaScript bundles and assets from a CDN. For a comprehensive guide on setting up CDN with Shakapacker, including CloudFlare configuration, troubleshooting, and advanced setups, see the [CDN Setup Guide](cdn_setup.md).

**Quick Setup**: Set the `SHAKAPACKER_ASSET_HOST` environment variable before compiling assets:

```bash
export SHAKAPACKER_ASSET_HOST=https://cdn.example.com
RAILS_ENV=production bundle exec rake assets:precompile
```

Note: Shakapacker does NOT use the `ASSET_HOST` environment variable. You must use `SHAKAPACKER_ASSET_HOST` instead (`WEBPACKER_ASSET_HOST` if using Shakapacker before v7).

## Capistrano

### Assets compiling on every deployment even if JavaScript and CSS files are not changed

Make sure you have your public output path (default `public/packs`), the shakapacker cache path (default `tmp/shakapacker`) and `node_modules` in `:linked_dirs`

```ruby
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/shakapacker", "public/packs", ".bundle", "node_modules"
```

If you have `node_modules` added to `:linked_dirs` you'll need to install your JavaScript dependencies before `deploy:assets:precompile`; you can use `package_json` to do this generically:

```ruby
before "deploy:assets:precompile", "deploy:js_install"
namespace :deploy do
  desc "Run rake js install"
  task :js_install do
    require "package_json"

    # this will use the package manager specified via `packageManager`, or otherwise fallback to `npm`
    native_js_install_command = PackageJson.read.manager.native_install_command(frozen: true).join(" ")

    on roles(:web) do
      within release_path do
        execute("cd #{release_path} && #{native_js_install_command}")
      end
    end
  end
end
```

You can also replace the use of `package_json` with the underlying native install command for your preferred package manager.
