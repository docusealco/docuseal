# Troubleshooting

## Flash of Unstyled Content (FOUC)

If you're experiencing FOUC where content briefly appears unstyled before CSS loads, see the [Preventing FOUC guide](./preventing_fouc.md) for solutions including proper `stylesheet_pack_tag` placement and `content_for` patterns for dynamic pack loading.

## Debugging your webpack config

1. Read the error message carefully. The error message will tell you the precise key value
   that is not matching what Webpack expects.

2. Put a `debugger` statement in your Webpack configuration and run `bin/shakapacker --debug-shakapacker`.
   If you have a node debugger installed, you'll see the Chrome debugger for your webpack
   config. For example, install the Chrome extension
   [NiM](https://chrome.google.com/webstore/detail/nodejs-v8-inspector-manag/gnhhdgbaldcilmgcpfddgdbkhjohddkj) and
   set the option for the dev tools to open automatically. Or put `chrome://inspect` in the URL bar.
   For more details on debugging, see the official
   [Webpack docs on debugging](https://webpack.js.org/contribute/debugging/#devtools)

3. Any arguments that you add to bin/shakapacker get sent to webpack. For example, you can pass `--debug` to switch loaders to debug mode. See [webpack CLI debug options](https://webpack.js.org/api/cli/#debug-options) for more information on the available options.

4. You can also pass additional options to the command to run the webpack-dev-server and start the webpack-dev-server with the option `--debug-shakapacker`

5. **Export your full webpack/rspack configuration for analysis**: Use the `bin/shakapacker-config` utility to export your complete resolved configuration. This is especially helpful for:
   - **Migrations**: Comparing configurations before and after migrating between webpack and rspack, or between different Shakapacker versions
   - **Debugging**: Inspecting the exact configuration webpack/rspack is using, including all merged settings
   - **AI Analysis**: Uploading the exported config to ChatGPT or other AI tools for troubleshooting

   **Installation**: The utility is installed when you run `rake shakapacker:binstubs` or can be used directly via `rake shakapacker:export_bundler_config`.

   **RECOMMENDED - Quick troubleshooting:**

   ```bash
   # Install the binstub (one-time setup)
   rake shakapacker:binstubs

   # Export EVERYTHING for troubleshooting (dev + prod, annotated YAML)
   bin/shakapacker-config --doctor
   # Creates: webpack-development-client.yaml, webpack-development-server.yaml,
   #          webpack-production-client.yaml, webpack-production-server.yaml
   ```

   **Other usage examples:**

   ```bash
   # Save current environment configs with auto-generated names
   bin/shakapacker-config --save
   # Creates: webpack-development-client.yaml, webpack-development-server.yaml

   # Save to specific directory
   bin/shakapacker-config --save --save-dir=./debug-configs

   # Export only client config for production
   bin/shakapacker-config --save --env=production --client-only
   # Creates: webpack-production-client.yaml

   # Compare development vs production configs
   bin/shakapacker-config --save --save-dir=./configs
   diff configs/webpack-development-client.yaml configs/webpack-production-client.yaml

   # View config in terminal (no files created)
   bin/shakapacker-config

   # Export without inline documentation annotations
   bin/shakapacker-config --save --no-annotate

   # Export in JSON format for programmatic analysis
   bin/shakapacker-config --save --format=json
   ```

   **Config files are automatically named:** `{bundler}-{env}-{type}.{ext}`
   - Examples: `webpack-development-client.yaml`, `rspack-production-server.yaml`
   - YAML format includes inline documentation explaining each config key
   - Separate files for client and server bundles (cleaner than combined)

   See `bin/shakapacker-config --help` for all available options.

6. **Validate your webpack/rspack builds**: Use `bin/shakapacker-config --validate` to test that all your build configurations compile successfully. This is especially useful for:
   - **CI/CD pipelines**: Catch configuration errors before deployment
   - **Migration testing**: Verify builds work after upgrading webpack, rspack, or Shakapacker
   - **Multi-environment testing**: Ensure all build configurations (dev, prod, HMR) compile correctly

   **Quick validation:**

   ```bash
   # Validate all builds defined in .bundler-config.yml
   bin/shakapacker-config --validate

   # Validate with full output logs (shows all webpack/rspack compilation output)
   bin/shakapacker-config --validate --verbose

   # Validate a specific build
   bin/shakapacker-config --validate-build=dev-hmr
   ```

   **Verbose Mode:**

   When using `--verbose`, you'll see:
   - A clear header indicating verbose mode is enabled
   - Full real-time compilation output from webpack/rspack
   - All warnings and progress messages
   - Detailed error traces
   - Separators between builds for clarity

   This is useful for debugging compilation issues or understanding build performance.

   **Setting up build configurations:**

   ```bash
   # Create a .bundler-config.yml file with example builds
   bin/shakapacker-config --init

   # List all available builds
   bin/shakapacker-config --list-builds

   # Validate all builds
   bin/shakapacker-config --validate
   ```

   **Advanced options:**

   The validator uses a default timeout of 2 minutes per build. For large projects or slow CI environments, you can customize this behavior by modifying the `ValidatorOptions` in your code, or by adjusting your build configuration to be more efficient.

   If validation times out, try:
   - Using `--verbose` to see where the build is hanging
   - Optimizing your webpack/rspack configuration for faster builds
   - Running validation on a single build with `--validate-build=build-name`

   **How it works:**

   The validator will:
   - For HMR builds (with `WEBPACK_SERVE=true`): Start webpack-dev-server, wait for successful compilation, then shut down
   - For static builds: Run webpack/rspack and check for compilation errors
   - Report all errors and warnings with clear output
   - Exit with code 1 if any build fails (perfect for CI)

   **Example output:**

   ```text
   🔍 Validating Builds
   ================================================================================

   📦 Validating build: dev-hmr
      ✅ Build passed

   📦 Validating build: dev
      ✅ Build passed

   📦 Validating build: prod
      ❌ Build failed with 2 error(s)

   ================================================================================
   🔍 Build Validation Results
   ================================================================================

   ✅ Build: dev-hmr (2.34s)
      📦 Outputs: client
      ⚙️  Config: config/webpack/webpack.config.js

   ✅ Build: dev (3.12s)
      📦 Outputs: client, server
      ⚙️  Config: config/webpack/webpack.config.js
      📁 Output: /app/public/packs

   ❌ Build: prod (4.56s)
      📦 Outputs: client, server
      ⚙️  Config: config/webpack/webpack.config.js
      📁 Output: /app/public/packs
      ❌ 2 error(s)
         Module not found: Error: Can't resolve './missing'
         SyntaxError: Unexpected token

   ================================================================================
   Summary: 2/3 builds passed, 1 failed (Total: 10.02s)
   ================================================================================

   💡 Debugging Tips:
      To get more details, run individual builds with --verbose:

      bin/shakapacker-config --validate-build prod --verbose

      Or validate all builds with full output: bin/shakapacker-config --validate --verbose
   ================================================================================
   ```

   **Debugging Failed Builds:**

   When builds fail, the validator automatically provides debugging commands. You can:
   1. **Run a specific build with verbose output** to see full webpack/rspack logs:

      ```bash
      bin/shakapacker-config --validate-build prod --verbose
      ```

   2. **Validate all builds with verbose output** to see everything:

      ```bash
      bin/shakapacker-config --validate --verbose
      ```

   3. **Test individual builds manually** using the same configuration:

      ```bash
      # For static builds
      NODE_ENV=production RAILS_ENV=production bundle exec webpack --config config/webpack/webpack.config.js

      # For HMR/dev-server builds
      NODE_ENV=development WEBPACK_SERVE=true bundle exec webpack serve --config config/webpack/webpack.config.js
      ```

   The verbose mode shows:
   - Full real-time compilation output
   - All webpack/rspack warnings and progress messages
   - Detailed stack traces for errors
   - Timing information for each build phase
   - Clear separators between different builds

7. Generate webpack stats for build analysis (useful for bundle size optimization):

   ```bash
   NODE_ENV=development bin/shakapacker --profile --json > /tmp/webpack-stats.json
   ```

   ChatGPT and other AI tools can consume this output file. Change the NODE_ENV per your needs.

## Incorrect peer dependencies

Shakapacker uses peer dependencies to make it easier to manage what versions are being used for your app, which is especially
useful for patching security vulnerabilities. However, not all package managers will actually enforce these versions - notably,
Yarn will omit a warning rather than erroring if you forget to update a peer dependency:

```
warning " > shakapacker@6.1.1" has incorrect peer dependency "compression-webpack-plugin@^9.0.0".
```

This omission resulted in an error in the browser:

```
Failed to load resource: net::ERR_CONTENT_DECODING_FAILED
```

The error was caused by an old version of the peer dependency `webpack-compression-plugin`.

So, be sure to investigate warnings from `yarn install`!

## NoMethodError: undefined method 'deep_symbolize_keys' for nil:NilClass

If you see this error during deployment (especially on Heroku with a staging environment):

```
NoMethodError: undefined method 'deep_symbolize_keys' for nil:NilClass
  from shakapacker/configuration.rb:XXX:in 'load'
```

This happens when deploying to a custom Rails environment (like `staging`) that isn't explicitly defined in your `config/shakapacker.yml` file.

**Solution:** This was fixed in Shakapacker v9.1.1+. Upgrade to the latest version:

```ruby
# Gemfile
gem 'shakapacker', '~> 9.1'
```

After upgrading, Shakapacker will automatically fall back to sensible defaults when your environment isn't defined:

1. First tries your environment (e.g., `staging`)
2. Falls back to `production` configuration

**Alternative:** If you can't upgrade immediately, explicitly add your environment to `config/shakapacker.yml`:

```yaml
staging:
  <<: *default
  compile: false
  cache_manifest: true
```

See the [deployment guide](./deployment.md#custom-rails-environments-eg-staging) for more details.

## ENOENT: no such file or directory - node-sass

If you get the error `ENOENT: no such file or directory - node-sass` on deploy with
`assets:precompile` or `bundle exec rake shakapacker:compile` you may need to
move Sass to production `dependencies`.

Move any packages that related to Sass (e.g. `node-sass` or `sass-loader`) from
`devDependencies` to `dependencies` in `package.json`. This is because
shakapacker is running on a production system with the Rails workflow to build
the assets. Particularly on hosting providers that try to detect and do the right
thing, like Heroku.

However, if you get this on local development, or not during a deploy then you
may need to rebuild `node-sass`. It's a bit of a weird error; basically, it
can't find the `node-sass` binary. An easy solution is to create a postinstall
hook to ensure `node-sass` is rebuilt whenever new modules are installed.

In `package.json`:

```json
"scripts": {
  "postinstall": "npm rebuild node-sass"
}
```

## Can't find hello_react.js in manifest.json

- If you get this error `Can't find hello_react.js in manifest.json`
  when loading a view in the browser it's because webpack is still compiling packs.
  Shakapacker uses a `manifest.json` file to keep track of packs in all environments,
  however since this file is generated after packs are compiled by webpack. So,
  if you load a view in browser whilst webpack is compiling you will get this error.
  Therefore, make sure webpack
  (i.e `./bin/shakapacker-dev-server`) is running and has
  completed the compilation successfully before loading a view.

## throw er; // Unhandled 'error' event

- If you get this error while trying to use Elm, try rebuilding Elm. You can do
  so with a postinstall hook in your `package.json`:

```json
"scripts": {
  "postinstall": "npm rebuild elm"
}
```

## webpack or webpack-dev-server not found

- This could happen if `shakapacker:install` step is skipped. Please run `bundle exec rake shakapacker:install` to fix the issue.

- If you encounter the above error on heroku after upgrading from Rails 4.x to 5.1.x, then the problem might be related to missing `yarn` binstub. Please run following commands to update/add binstubs:

```bash
bundle config --delete bin
bundle exec rake app:update:bin
```

## Running webpack on Windows

If you are running webpack on Windows, your command shell may not be able to interpret the preferred interpreter
for the scripts generated in `bin/shakapacker` and `bin/shakapacker-dev-server`. Instead you'll want to run the scripts
manually with Ruby:

```
C:\path>ruby bin\webpack
C:\path>ruby bin\webpack-dev-server
```

## Invalid configuration object. webpack has been initialised using a configuration object that does not match the API schema.

If you receive this error when running `$ ./bin/shakapacker-dev-server` ensure your configuration is correct; most likely the path to your "packs" folder is incorrect if you modified from the original "source_path" defined in `config/shakapacker.yml`.

## Running Elm on Continuous Integration (CI) services such as CircleCI, CodeShip, Travis CI

If your tests are timing out or erroring on CI it is likely that you are experiencing the slow Elm compilation issue described here: [elm-compiler issue #1473](https://github.com/elm-lang/elm-compiler/issues/1473)

The issue is related to CPU count exposed by the underlying service. The basic solution involves using [libsysconfcpus](https://github.com/obmarg/libsysconfcpus) to change the reported CPU count.

Basic fix involves:

```bash
# install sysconfcpus on CI

git clone https://github.com/obmarg/libsysconfcpus.git $HOME/dependencies/libsysconfcpus
cd libsysconfcpus
.configure --prefix=$HOME/dependencies/sysconfcpus
make && make install

# use sysconfcpus with elm-make
mv $HOME/your_rails_app/node_modules/.bin/elm-make $HOME/your_rails_app/node_modules/.bin/elm-make-old
printf "#\041/bin/bash\n\necho \"Running elm-make with sysconfcpus -n 2\"\n\n$HOME/dependencies/sysconfcpus/bin/sysconfcpus -n 2 $HOME/your_rails_app/node_modules/.bin/elm-make-old \"\$@\"" > $HOME/your_rails_app/node_modules/.bin/elm-make
chmod +x $HOME/your_rails_app/node_modules/.bin/elm-make
```

## Rake assets:precompile fails. ExecJS::RuntimeError

This error occurs because you are trying to minify by `terser` a pack that's already been minified by Shakapacker. To avoid this conflict and prevent appearing of `ExecJS::RuntimeError` error, you will need to disable uglifier from Rails config:

```ruby
# In production.rb

# From
Rails.application.config.assets.js_compressor = :uglifier

# To
Rails.application.config.assets.js_compressor = Uglifier.new(harmony: true)
```

### Angular: WARNING in ./node_modules/@angular/core/esm5/core.js, Critical dependency: the request of a dependency is an expression

To silent these warnings, please update `config/webpack/webpack.config.js`:

```js
const webpack = require("webpack")
const { resolve } = require("path")
const { generateWebpackConfig } = require("shakapacker")

module.exports = generateWebpackConfig({
  plugins: [
    new webpack.ContextReplacementPlugin(
      /angular(\\|\/)core(\\|\/)(@angular|esm5)/,
      resolve(config.source_path)
    )
  ]
})
```

### Compilation Fails Silently

If compiling is not producing output files and there are no error messages to help troubleshoot. Setting the `webpack_compile_output` configuration variable to `true` in shakapacker.yml may add some helpful error information to your log file (Rails `log/development.log` or `log/production.log`)

```yml
# shakapacker.yml
default: &default
  source_path: app/javascript
  source_entry_path: packs
  public_root_path: public
  public_output_path: complaints_packs
  webpack_compile_output: true
```

### Using global variables for dependencies

If you want to access any dependency without importing it everywhere or use it directly in your dev tools, please check: [https://webpack.js.org/plugins/provide-plugin/](https://webpack.js.org/plugins/provide-plugin/) and the [webpack docs on shimming globals](https://webpack.js.org/guides/shimming/#shimming-globals).

Note, if you are exposing globals, like jQuery, to non-webpack dependencies (like an inline script) via the [expose-loader](https://webpack.js.org/loaders/expose-loader/), you will need to override the default of `defer: true` to be `defer:false` your call to the `javascript_pack_tag` so that the browser will load your bundle to set up the global variable before other code depends on it. However, you really should try to remove the dependency on such globals.

Thus ProvidePlugin manages build-time dependencies to global symbols whereas the expose-loader manages runtime dependencies to global symbols.

**You don't need to assign dependencies on `window`.**

For instance, with [jQuery](https://jquery.com/):

```diff
// app/javascript/entrypoints/application.js

- import jQuery from 'jquery'
- window.jQuery = jQuery
```

Instead do:

```js
// config/webpack/webpack.config.js

const webpack = require("webpack")
const { generateWebpackConfig } = require("shakapacker")

module.exports = generateWebpackConfig({
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery"
    })
  ]
})
```

## Wrong CDN src from javascript_pack_tag

If your deployment doesn't rebuild assets between environments (such as when
using Heroku's Pipeline promote feature). You might find that your production
application is using your staging `config.asset_host` host when using
`javascript_pack_tag`.

This can be fixed by setting the environment variable `SHAKAPACKER_ASSET_HOST` to
an empty string where your assets are compiled. On Heroku this is done under
_Settings_ -> _Config Vars_.

This way shakapacker won't hard-code the CDN host into the manifest file used by
`javascript_pack_tag`, but instead fetch the CDN host at runtime, resolving the
issue.

See [this issue](https://github.com/rails/webpacker/issues/3005) for more
details.

## Static file dependencies emitted outside of public output path

For static file assets (images, fonts), we use [a Webpack rule](https://github.com/shakacode/shakapacker/blob/main/package/rules/file.js) to handle those files as `asset/resource` type and output them in the `static` folder in the public output path.

In order to generate the storage path, we rely on the filename that's [provided by webpack internals](https://webpack.js.org/configuration/output/#outputfilename).

This usually works out of the box. There's a potential problem however, if you use the [context setting](https://webpack.js.org/configuration/entry-context/#context) in your webpack config. By default this is set to current Node working directory/project root.

If you were to override it like:

```
{
  context: path.resolve(__dirname, '../../app/javascript')
}
```

Then the filename available in the rule generator will be relative to that directory.

This means for example:

- a static asset from `node_modules` folder could end up being referenced with path of `../../node_modules/some_module/static_file.jpg` rather than simply `node_modules/some_module/static_file.jpg`.
- a static asset in one of the `additional_paths`, example `app/assets/images/image.jpg`, would end up being referenced with path of `../assets/images/image.jpg`.

Those paths are later passed to [output path generation in the rule](https://github.com/shakacode/shakapacker/blob/e52b335dbabfb934fe7d3076a8322b97d5ef3470/package/rules/file.js#L25-L26), where we would end up with a path like `static/../../node_modules/some_module/static_file.jpg`, resulting in the file being output in a location two directories above the desired path.

You can avoid this by:

- not using overridden `context` in your webpack config, if there's no good reason for it.
- using custom Webpack config to modify the static file rule, following a similar process as outlined in the [Webpack Configuration](https://github.com/shakacode/shakapacker/blob/main/README.md#webpack-configuration) section of the readme.

See [this issue](https://github.com/shakacode/shakapacker/issues/538) for more details.
