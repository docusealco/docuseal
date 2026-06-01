## Plugins

Puma 3.0 added support for plugins that can augment configuration and service
operations.

There are two canonical plugins to aid in the development of new plugins:

* [tmp\_restart](https://github.com/puma/puma/blob/main/lib/puma/plugin/tmp_restart.rb):
  Restarts the server if the file `tmp/restart.txt` is touched
* [heroku](https://github.com/puma/puma-heroku/blob/master/lib/puma/plugin/heroku.rb):
  Packages up the default configuration used by Puma on Heroku (being sunset
  with the release of Puma 5.0)

Plugins are activated in a Puma configuration file (such as `config/puma.rb`)
by adding `plugin "name"`, such as `plugin "heroku"`.

Plugins are activated based on path requirements so, activating the `heroku`
plugin is much like `require "puma/plugin/heroku"`. This allows gems to provide
multiple plugins (as well as unrelated gems to provide Puma plugins).

The `tmp_restart` plugin comes with Puma, so it is always available.

To use the `heroku` plugin, add `puma-heroku` to your Gemfile or install it.

### API

## Server-wide hooks

Plugins can use a couple of hooks at the server level: `start` and `config`.

`start` runs when the server has started and allows the plugin to initiate other
functionality to augment Puma.

`config` runs when the server is being configured and receives a `Puma::DSL`
object that is useful for additional configuration.

Public methods in [`Puma::Plugin`](../lib/puma/plugin.rb) are treated as a
public API for plugins.

## Binder hooks

There's `Puma::Binder#before_parse` method that allows to add proc to run before the body of `Puma::Binder#parse`. Example of usage can be found in [that repository](https://github.com/anchordotdev/puma-acme/blob/v0.1.3/lib/puma/acme/plugin.rb#L97-L118) (`before_parse_hook` could be renamed `before_parse`, making monkey patching of [binder.rb](https://github.com/anchordotdev/puma-acme/blob/v0.1.3/lib/puma/acme/binder.rb) is unnecessary).