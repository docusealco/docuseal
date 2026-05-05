# frozen_string_literal: true

module DownloadUtils
  LOCALHOSTS = Set[
    '0.0.0.0',
    '127.0.0.1',
    '127.0.1.1',
    'localhost',
    'localhost.localdomain',
    '::1',
    '[::1]',
    'ip6-localhost',
    'ip6-loopback',
    '127.0.0.0',
    '127.255.255.255',
    '::',
    '0:0:0:0:0:0:0:1',
    '[0:0:0:0:0:0:0:1]',
    '0000:0000:0000:0000:0000:0000:0000:0001',
    '[0000:0000:0000:0000:0000:0000:0000:0001]',
    '::0',
    '0::0',
    '::ffff:127.0.0.1',
    '[::ffff:127.0.0.1]',
    '::ffff:7f00:1',
    '[::ffff:7f00:1]',
    'local',
    'localhost.local',
    'ip6-localnet',
    'ip6-allnodes',
    'ip6-allrouters'
  ].freeze

  BLOCKED_CIDRS = [
    IPAddr.new('10.0.0.0/8'),
    IPAddr.new('172.16.0.0/12'),
    IPAddr.new('192.168.0.0/16'),
    IPAddr.new('127.0.0.0/8'),
    IPAddr.new('169.254.0.0/16'),
    IPAddr.new('100.64.0.0/10'),
    IPAddr.new('::1/128'),
    IPAddr.new('fc00::/7'),
    IPAddr.new('fe80::/10')
  ].freeze

  UnableToDownload = Class.new(StandardError)

  module_function

  def call(url, validate: Docuseal.multitenant?)
    uri = begin
      URI(url)
    rescue URI::Error
      Addressable::URI.parse(url).normalize
    end

    validate_uri!(uri) if validate

    resp = conn(validate:).get(uri)

    raise UnableToDownload, "Error loading: #{uri}" if resp.status >= 400

    resp
  end

  def validate_uri!(uri)
    raise UnableToDownload, "Error loading: #{uri}. Only HTTPS is allowed." if uri.scheme != 'https' ||
                                                                               [443, nil].exclude?(uri.port)
    raise UnableToDownload, "Error loading: #{uri}. Can't download from localhost." if uri.host.in?(LOCALHOSTS)

    validate_resolved_ip!(uri.host)
  end

  def validate_resolved_ip!(host)
    addresses = Resolv.getaddresses(host)

    addresses.each do |addr|
      ip = begin
        IPAddr.new(addr)
      rescue IPAddr::InvalidAddressError
        next
      end

      if BLOCKED_CIDRS.any? { |cidr| cidr.include?(ip) }
        raise UnableToDownload, "Can't download from private/reserved IP: #{addr}"
      end
    end
  end

  def conn(validate: Docuseal.multitenant?)
    Faraday.new do |faraday|
      faraday.response :follow_redirects, callback: lambda { |_, new_env|
        validate_uri!(new_env[:url]) if validate
      }
    end
  end
end
