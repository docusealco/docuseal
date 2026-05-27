# Upgrading from Shakapacker v6 to v7

There are several breaking changes in Shakapacker v7 that you need to manually account for when coming from Shakapacker v6.

## Usages of `webpacker` should now be `shakapacker`

Shakapacker v6 kept the 'webpacker' spelling. As a result, many config filenames, environment variables, rake tasks, etc., used the 'webpacker' spelling. Shakapacker 7 requires renaming to the 'shakapacker' spelling.

Shakapacker v7 provides a high degree of backward compatibility for spelling changes. It displays deprecation messages in the terminal to help the developers have a smooth experience in making the required transition to the new requirements.

Just so you know, Shakapacker v8 will remove any backward compatibility for spelling.

### Upgrade Steps

**Note:** At each step of changing the version, ensure that you update both gem and npm versions to the same "exact" version (like `x.y.z` and not `^x.y.z` or `>= x.y.z`).

1. Upgrade Shakapacker to the latest 6.x version and make sure there are no issues running your application.
2. Upgrade Shakapacker to version 7.
3. Run `rake shakapacker:binstubs` to get the new files in place. Then delete the `bin/webpacker` and `bin/webpacker-dev-server` ones.
4. Change spelling from Webpacker to Shakapacker in the code
   - Change `webpacker_precompile` entry to `shakapacker_precompile` if it exists in the config file.
   - Rename Ruby constant `Webpacker` to `Shakapacker` by doing a global search and replace in your code. You might not be using it.
     - Rename`Shakapacker.config.webpacker_precompile?` method, replace it with `Shakapacker.config.shakapacker_precompile?`
   - `--debug-webpacker` is now `--debug-shakapacker` for your shakapacker binstubs.
5. Rename files
   - Rename `config/webpacker.yml` to `config/shakapacker.yml`.
   - Rename environment variables from `WEBPACKER_XYZ` to `SHAKAPACKER_XYZ`.
6. Where you have used webpackConfig, you must create a new instance with `generateWebpackConfig`. Alternatively, you can rename the import to globalMutableWebpackConfig, which retains the v6 behavior of a global, mutable object.
7. You may need to upgrade dependencies in package.json. You should use `yarn upgrade-interactive`.

## Stop stripping top-level dirs for static assets

When generating file paths for static assets, a top-level directory will no longer be stripped. This will necessitate the update of file name references in asset helpers. For example, the file sourced from `app/javascript/images/image.png` will now be output to `static/images/image.png`, and needs to be referenced as `image_pack_tag("images/image.jpg")` or `image_pack_tag("static/images/image.jpg")`. Nested directories are supported.

## The `webpackConfig` property is changed

The `webpackConfig` property in the `shakapacker` module has been changed. The shakapacker module has two options:

1. `generateWebpackConfig`: a function that returns a new webpack configuration object, which ensures that any modifications made to it will not affect any other usage of the webpack configuration.
2. `globalMutableWebpackConfig`: if a project still desires the old mutable object. You can rename your imports of `webpackConfig` with `globalMutableWebpackConfig`.

## Example Upgrade

If you started with:

```js
const { webpackConfig } = require("shakapacker")
```

Switch to:

```js
const { generateWebpackConfig } = require("shakapacker")
const webpackConfig = generateWebpackConfig()
```

or use `globalMutableWebpackConfig` if the project desires to use a globally mutable object.

```js
const { globalMutableWebpackConfig: webpackConfig } = require("shakapacker")
```
