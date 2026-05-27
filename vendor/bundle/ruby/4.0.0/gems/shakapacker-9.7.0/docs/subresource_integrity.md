# Subresource integrity

It's a cryptographic hash that helps browsers check that the served js or css file has not been tampered in any way.

[MDN - Subresource Integrity](https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity)

## Important notes

- If you somehow modify the file after the hash was generated, it will automatically be considered as tampered, and the browser will not allow it to be executed.
- Enabling subresource integrity generation, will change the structure of `manifest.json`. Keep that in mind if you utilize this file in any other custom implementation.

Before:

```json
{
  "application.js": "/path_to_asset"
}
```

After:

```json
{
  "application.js": {
    "src": "/path_to_asset",
    "integrity": "<sha256-hash> <sha384-hash> <sha512-hash>"
  }
}
```

## Possible CORS issues

Enabling subresource integrity for an asset, actually enforces CORS checks on that resource too. Which means that
if you haven't set that up properly beforehand, it will probably lead to CORS errors with cached assets.

[MDN - How browsers handle Subresource Integrity](https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity#how_browsers_handle_subresource_integrity)

## Configuration

By default, this setting is disabled, to ensure backwards compatibility, and let developers adapt at their own pace.
This may change in the future, as it is a very nice security feature, and it should be enabled by default.

To enable it, just add this in `shakapacker.yml`

```yml
integrity:
  enabled: true
```

For further customization, you can also utilize the options `hash_functions` that control the functions used to generate
integrity hashes. And `cross_origin` that sets the cross-origin loading attribute.

```yml
integrity:
  enabled: true
  hash_functions: ["sha256", "sha384", "sha512"]
  cross_origin: "anonymous" # or "use-credentials"
```

This will utilize under the hood webpack-subresource-integrity plugin and will modify `manifest.json` to include integrity hashes.
