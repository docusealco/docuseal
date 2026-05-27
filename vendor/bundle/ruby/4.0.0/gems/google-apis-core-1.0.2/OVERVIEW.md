# Core classes for Google REST Clients

This library includes common base classes and dependencies used by legacy REST
clients for Google APIs. It is used by client libraries, but you should not
need to install it by itself.

## Usage

In most cases, this library is installed automatically as a dependency of
another library. For example, if you install the
[google-apis-drive_v3](https://rubygems.org/gems/google-apis-drive_v3) client
library, it will bring in the latest `google-apis-core` as a dependency. Thus,
in most cases, you do not need to add `google-apis-core` to your Gemfile
directly.

Earlier (0.x) versions of this library utilized the legacy
[httpclient](https://rubygems.org/gems/httpclient) gem and made some of its
interfaces available for advanced use cases. Version 1.0 and later of this
library replaced httpclient with [faraday](https://rubygems.org/gems/faraday).
If your application makes use of the httpclient interfaces (this is rare), you
should pin `google-apis-core` to a 0.x version in your Gemfile. For example:

    gem "google-apis-core", "~> 0.18"

## Documentation

More detailed descriptions of the Google legacy REST clients are available in two documents.

 *  The [Usage Guide](https://github.com/googleapis/google-api-ruby-client/blob/main/docs/usage-guide.md) discusses how to make API calls, how to use the provided data structures, and how to work the various features of the client library, including media upload and download, error handling, retries, pagination, and logging.
 *  The [Auth Guide](https://github.com/googleapis/google-api-ruby-client/blob/main/docs/auth-guide.md) discusses authentication in the client libraries, including API keys, OAuth 2.0, service accounts, and environment variables.

For reference information on specific calls in the clients, see the {Google::Apis class reference docs}.

## License

This library is licensed under Apache 2.0. Full license text is available in the {file:LICENSE.md LICENSE}.

## Support

Please [report bugs at the project on Github](https://github.com/google/google-api-ruby-client/issues). Don't hesitate to [ask questions](http://stackoverflow.com/questions/tagged/google-api-ruby-client) about the client or APIs on [StackOverflow](http://stackoverflow.com).
