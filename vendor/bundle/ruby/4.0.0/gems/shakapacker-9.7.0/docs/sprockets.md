# Sprockets

### Note for Sprockets usage

If you are still using Sprockets for some of your assets, you might want to include files from `node_modules` directory in your asset pipeline. This is useful, for example, if you want to reference a stylesheet from a node package in your `.scss` stylesheet.

In order to enable this, make sure you add `node_modules` to the asset load path by adding the following in an initializer (for example `config/initializers/assets.rb`)

```ruby
Rails.application.config.assets.paths << Rails.root.join('node_modules')
```
