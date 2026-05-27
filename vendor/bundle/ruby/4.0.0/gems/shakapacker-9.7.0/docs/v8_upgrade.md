# Upgrading from Shakapacker v7 to v8

The majority of the breaking changes in v8 were about dropping deprecated
functions and features, along with switching to be agnostic about what package
manager is used to manage JavaScript dependencies.

Support for Ruby 2.6 and Node v12 has also been dropped since they're very old
at this point.

## CDN host is stripped from the manifest output

In Webpacker v5, the manifest.json file did not include the CDN asset host if defined. THis has been added in the aborted v6 and we've retained this in Shakapacker.

Presence of this host in the output could lead to unexpected issues and required [some workarounds](https://github.com/shakacode/shakapacker/blob/main/docs/troubleshooting.md#wrong-cdn-src-from-javascript_pack_tag) in certain cases.

If you are not using CDN, then this change will have no effect on your setup.

If you are using CDN and your CDN host is static, `config.asset_host` setting in Rails will be respected during compilation and when referencing assets through view helpers.

If your host might differ, between various environments for example, you will either need to:

- Ensure the assets are specifically rebuilt for each environment (Heroku pipeline promote feature for example does not do that by default).
- Make sure the assets are compiled with `SHAKAPACKER_ASSET_HOST=''` ENV variable to avoid hardcording URLs in packs output.

The second option has got a certain gotcha - dynamic imports and static asset references (like image paths in CSS) will end up without a host reference and the app will try and fetch them from your app host rather than defined `config.asset_host`.

To get around that, you can use dynamic override as outlined by [Webpack documentation](https://webpack.js.org/guides/asset-modules/#on-the-fly-override).

Setting for example:

```
__webpack_public_path__ = 'https://mycdn.url.com/packs';
```

In your code and ensuring it is run first in the app, will allow the dynamic imports lookup path to be overridden at runtime.

You can also try Webpack `output.publicPath` option of `'auto'` as per https://webpack.js.org/guides/public-path/#automatic-publicpath.

For example in your `webpack.config.js`:

```
const { generateWebpackConfig } = require('shakapacker')

const customConfig = {
  output: {
    publicPath: 'auto'
  }
};

module.exports = generateWebpackConfig(customConfig);
```

This will work in number of environments although some older browsers like IE will require a polyfill as mentioned in the Webpack documentation linked above.

## The `packageManager` property in `package.json` is used to determine the package manager

The biggest functional change in v8, `shakapacker` can now work with any
of the major JavaScript package managers thanks to the
[`package_json`](https://github.com/shakacode/package_json) gem which uses the
[`packageManager`](https://nodejs.org/api/packages.html#packagemanager) property
in the `package.json`.

In alignment with the behaviour of Node and `corepack`, in the absence of the
`packageManager` property `npm` will be used as the package manager so as part
of upgrading you will want to ensure that is set to `yarn@<version>` if you want
to continue using Yarn.

An error will be raised in the presences of a lockfile other than
`package-lock.json` if this property is not set with the recommended value to
use, but it important the property is set to ensure all tooling uses the right
package manager.

The `check_yarn` rake task has also been renamed to `check_manager` to reflect
this change.

Check out the [installation section](../README.md#installation) of the readme
for more details.

## Usages of `webpacker` must now be `shakapacker`

The `webpacker` spelling was deprecated in v7 and has now been completely
removed in v8 - this includes constants, environment variables, and rake tasks.

If you are still using references to `webpacker`, see the
[v7 Upgrade Guide](../docs/v7_upgrade.md) for how to migrate.

## JavaScript dependencies are no longer installed automatically as part of `assets:precompile`

You will now need to ensure your dependencies are installed before compiling
assets.

Some platforms like Heroku will install dependencies automatically but if you're
using a tool like `capistrano` to deploy to servers you can enhance the
`assets:precompile` command like so:

```ruby
namespace :assets do
  desc "Ensures that dependencies required to compile assets are installed"
  task install_dependencies: :environment do
    # npm v6+
    raise if File.exist?("package.json") && !(system "npm ci")

    # yarn v1.x (classic)
    raise if File.exist?("package.json") && !(system "yarn install --frozen-lockfile")

    # yarn v2+ (berry)
    raise if File.exist?("package.json") && !(system "yarn install --immutable")

    # bun v1+
    raise if File.exist?("package.json") && !(system "bun install --frozen-lockfile")

    # pnpm v6+
    raise if File.exist?("package.json") && !(system "pnpm install --frozen-lockfile")
  end
end

Rake::Task["assets:precompile"].enhance ["assets:install_dependencies"]
```

This allows more flexibility than what `shakapacker` could provide - for
example, you might only want to do an immutable install if you're in CI.

## `ensure_consistent_versioning` is now enabled by default

This has `shakapacker` check that the versions of the installed Ruby gem and
JavaScript package are compatible; this should only be impactful for codebases
that are not using lockfiles.

## Usages of `globalMutableWebpackConfig` must be replaced with `generateWebpackConfig()`

The function will return the same object with less risk:

```js
// before
const { globalMutableWebpackConfig, merge } = require("shakapacker")

const customConfig = {
  module: {
    rules: [
      {
        test: require.resolve("jquery"),
        loader: "expose-loader",
        options: { exposes: ["$", "jQuery"] }
      }
    ]
  }
}

module.exports = merge(globalMutableWebpackConfig, customConfig)
```

```js
// after
const { generateWebpackConfig, merge } = require("shakapacker")

const customConfig = {
  module: {
    rules: [
      {
        test: require.resolve("jquery"),
        loader: "expose-loader",
        options: { exposes: ["$", "jQuery"] }
      }
    ]
  }
}

// you can also pass your config directly to the generator function to have it merged in!
module.exports = merge(generateWebpackConfig(), customConfig)
```

## `additional_paths` are now stripped just like with `source_path`

This means going forward asset paths should be same regardless of their source:

```erb
<%# before %>
<%= image_pack_tag('marketing/images/people_looking_happy.png') %>

<%# after %>
<%= image_pack_tag('image/people_looking_happy.png') %>
```

## Misc. removals

In addition to the above, v8 has also removed a number of miscellaneous
functions that no one is probably using anyway but technically could have been
including:

- `isArray` js utility function (just use `Array.isArray` directly)
- `relative_url_root` config getter (it was never used)
- `verify_file_existance` method (use `verify_file_existence` instead)
- `https` option for `webpack-dev-server` (use `server: 'https'` instead)
