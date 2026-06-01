# CSS Delivery In Development

You have two options for serving CSS in development:

1. You can opt to serve CSS via style-loader (as was traditionally done in a Webpack setup), where CSS is written by Javascript served by Shakapacker into a `<style>` tag, or
2. You can opt to serve CSS as a full CSS file via mini-css-extract-plugin, which uses a standard `<link>` tag to load a fully separate CSS file.

Both options support HMR. The default is style-loader. If you want to use mini-css-extract-plugin in development, set `inline_css: false` in the development dev_server section of your shakapacker.yml:

```yml
development:
  <<: *default
  dev_server:
    hmr: true
    inline_css: false # Use mini-css-extract-plugin for CSS delivery
```

## Why would I pick style-loader?

style-loader is how you are probably are used to serving CSS in development with HMR in Webpack.

### benefits

- No [Flash Of Unstyled Content (FOUC)](https://en.wikipedia.org/wiki/Flash_of_unstyled_content) on HMR refreshes
- Smaller/faster incremental updates.

### drawbacks

- Inflated JS deliverable size; requires JS execution before CSS is available
- FOUC on initial page load
- Adds an extra dependency
- Divergence in delivery mechanism from production

## Why would I pick mini-css-extract-plugin?

mini-css-extract-plugin's behavior is much more true to a production deployment's behavior, in that CSS is loaded via `link rel=stylsheet` tags, rather than injected by Javascript into `style` tags.

### benefits

- Required for production, so it's going to be in play anyhow. Using only it simplifies the config and eliminates the style-loader dependency.
- No FOUC on initial page loads
- CSS delivered via `<link>` tags matches the mechanism used in production (I have been guilty of omitting my `stylesheet_pack_tag` for my first deploy because CSS worked fine with just the `javascript_pack_tag` in development.)

### drawbacks

- Invokes a separate HTTP request, compared to style-loader
- Potential for FOUC on HMR refreshes
- More data transferred per refresh (full stylesheet reload, rather than just an incremental patch). Not likely to be noticed for local development, but still a technical difference. This may only be the case [when you're using local CSS modules](https://github.com/webpack-contrib/mini-css-extract-plugin/blob/master/src/hmr/hotModuleReplacement.js#L267-L273).
