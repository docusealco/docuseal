# frozen_string_literal: true

module DownloadUtils
  LOCALHOSTS = %w[0.0.0.0 127.0.0.1 localhost].freeze

  UnableToDownload = Class.new(StandardError)

  module_function

  def call(url)
    uri = Addressable::URI.parse(url)

    if Docuseal.multitenant?
      raise UnableToDownload, "Error loading: #{uri.display_uri}. Only HTTPS is allowed." if uri.scheme != 'https'

      if uri.host.in?(LOCALHOSTS)
        raise UnableToDownload, "Error loading: #{uri.display_uri}. Can't download from localhost."
      end
    end

    resp = conn.get(uri.display_uri.to_s)

    raise UnableToDownload, "Error loading: #{uri.display_uri}" if resp.status >= 400

    resp
  end

  def conn
    Faraday.new do |faraday|
      faraday.response :follow_redirects
    end
  end
end
