# frozen_string_literal: true

module DownloadUtils
  LOCALHOSTS = %w[0.0.0.0 127.0.0.1 localhost].freeze

  UnableToDownload = Class.new(StandardError)

  module_function

  def call(url)
    uri = begin
      URI(url)
    rescue URI::Error
      Addressable::URI.parse(url).normalize
    end

    if Docuseal.multitenant?
      raise UnableToDownload, "Error loading: #{uri}. Only HTTPS is allowed." if uri.scheme != 'https'
      raise UnableToDownload, "Error loading: #{uri}. Can't download from localhost." if uri.host.in?(LOCALHOSTS)
    end

    resp = conn.get(uri)

    raise UnableToDownload, "Error loading: #{uri}" if resp.status >= 400

    resp
  end

  def conn
    Faraday.new do |faraday|
      faraday.response :follow_redirects
    end
  end
end
