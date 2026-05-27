# frozen_string_literal: true

require 'seahorse/client/net_http/handler'

module Seahorse
  module Client
    module Plugins
      class NetHttp < Plugin

        option(:http_proxy, default: nil, doc_type: "URI::HTTP,String", docstring: <<-DOCS)
A proxy to send requests through.  Formatted like 'http://proxy.com:123'.
        DOCS

        option(:http_open_timeout, default: 15, doc_type: Float, docstring: <<-DOCS) do |cfg|
The default number of seconds to wait for response data.
This value can safely be set per-request on the session.
        DOCS
          resolve_http_open_timeout(cfg)
        end

        option(:http_read_timeout, default: 60, doc_type: Float, docstring: <<-DOCS) do |cfg|
The default number of seconds to wait for response data.
This value can safely be set per-request on the session.
        DOCS
          resolve_http_read_timeout(cfg)
        end

        option(:http_idle_timeout, default: 5, doc_type: Float, docstring: <<-DOCS)
The number of seconds a connection is allowed to sit idle before it 
is considered stale.  Stale connections are closed and removed from the 
pool before making a request.
        DOCS

        option(:http_continue_timeout, default: 1, doc_type: Float, docstring: <<-DOCS)
The number of seconds to wait for a 100-continue response before sending the 
request body.  This option has no effect unless the request has "Expect"
header set to "100-continue".  Defaults to `nil` which  disables this 
behaviour.  This value can safely be set per request on the session.
          DOCS

        option(:http_wire_trace, default: false, doc_type: 'Boolean', docstring: <<-DOCS)
When `true`,  HTTP debug output will be sent to the `:logger`.
        DOCS

        option(:ssl_verify_peer, default: true, doc_type: 'Boolean', docstring: <<-DOCS)
When `true`, SSL peer certificates are verified when establishing a connection.
        DOCS

        option(:ssl_ca_bundle, doc_type: String, docstring: <<-DOCS) do |cfg|
Full path to the SSL certificate authority bundle file that should be used when 
verifying peer certificates.  If you do not pass `:ssl_ca_bundle` or 
`:ssl_ca_directory` the the system default will be used if available.       
        DOCS
          ENV['AWS_CA_BUNDLE'] ||
            Aws.shared_config.ca_bundle(profile: cfg.profile) if cfg.respond_to?(:profile)
        end

        option(:ssl_ca_directory, default: nil, doc_type: String, docstring: <<-DOCS)
Full path of the directory that contains the unbundled SSL certificate 
authority files for verifying peer certificates.  If you do 
not pass `:ssl_ca_bundle` or `:ssl_ca_directory` the the system 
default will be used if available.
        DOCS

        option(:ssl_ca_store, default: nil, doc_type: String, docstring: <<-DOCS)
Sets the X509::Store to verify peer certificate.
        DOCS

        option(:ssl_timeout, default: nil, doc_type: Float, docstring: 'Sets the SSL timeout in seconds') do |cfg|
          resolve_ssl_timeout(cfg)
        end

        option(:ssl_cert, default: nil, doc_type: OpenSSL::X509::Certificate, docstring: <<-DOCS)
Sets a client certificate when creating http connections.
        DOCS


        option(:ssl_key, default: nil, doc_type: OpenSSL::PKey, docstring: <<-DOCS)
Sets a client key when creating http connections.
        DOCS

        option(:logger) # for backwards compat

        handler(Client::NetHttp::Handler, step: :send)

        def self.resolve_http_open_timeout(cfg)
          default_mode_value =
            if cfg.respond_to?(:defaults_mode_config_resolver)
              cfg.defaults_mode_config_resolver.resolve(:http_open_timeout)
            end
          default_mode_value || 15
        end

        def self.resolve_http_read_timeout(cfg)
          default_mode_value =
            if cfg.respond_to?(:defaults_mode_config_resolver)
              cfg.defaults_mode_config_resolver.resolve(:http_read_timeout)
            end
          default_mode_value || 60
        end

        def self.resolve_ssl_timeout(cfg)
          default_mode_value =
            if cfg.respond_to?(:defaults_mode_config_resolver)
              cfg.defaults_mode_config_resolver.resolve(:ssl_timeout)
            end
          default_mode_value || nil
        end
      end
    end
  end
end
