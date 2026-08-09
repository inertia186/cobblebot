require 'ipaddr'
require 'resolv'

class CobbleBotAgent < Mechanize
  class UnsafeUrlError < StandardError; end

  BLOCKED_NETWORKS = %w[
    0.0.0.0/8
    10.0.0.0/8
    100.64.0.0/10
    127.0.0.0/8
    169.254.0.0/16
    172.16.0.0/12
    192.0.0.0/24
    192.0.2.0/24
    192.168.0.0/16
    198.18.0.0/15
    198.51.100.0/24
    203.0.113.0/24
    224.0.0.0/4
    240.0.0.0/4
    ::/128
    ::1/128
    ::ffff:0:0/96
    100::/64
    2001:db8::/32
    fc00::/7
    fe80::/10
    ff00::/8
  ].map { |network| IPAddr.new(network) }.freeze

  module ValidatedFetch
    def fetch(uri, method = :get, headers = {}, params = [], referer = current_page, redirects = 0)
      resolved_uri = resolve(uri, referer)
      resolved_uri, addresses = CobbleBotAgent.validate_url_and_addresses!(resolved_uri)
      connection_for(resolved_uri).pin_address(resolved_uri, addresses.first)
      super
    end
  end

  module PinnedConnectionStart
    def pin_address(uri, address)
      pinned_addresses[[uri.hostname.downcase, uri.port]] = address
    end

    def pinned_address_for(uri)
      pinned_addresses[[uri.hostname.downcase, uri.port]]
    end

    def start(http)
      address = pinned_addresses[[http.address.downcase, http.port]]
      http.ipaddr = address if address.present? && !http.started?
      super
    end

  private
    def pinned_addresses
      @cobblebot_pinned_addresses ||= {}
    end
  end

  class << self
    def resolve_addresses(hostname)
      Resolv.getaddresses(hostname)
    end

    def validate_url!(url)
      validate_url_and_addresses!(url).first
    end

    def validate_url_and_addresses!(url)
      uri = url.is_a?(URI) ? url : URI.parse(url.to_s)
      hostname = uri.hostname.to_s.downcase.delete_suffix('.')

      unless %w[http https].include?(uri.scheme) && hostname.present? && uri.userinfo.nil?
        raise UnsafeUrlError, 'Only public HTTP and HTTPS URLs are allowed.'
      end

      if hostname == 'localhost' || hostname.end_with?('.localhost', '.local')
        raise UnsafeUrlError, 'Local network URLs are not allowed.'
      end

      addresses = begin
        [IPAddr.new(hostname).to_s]
      rescue IPAddr::InvalidAddressError
        resolve_addresses(hostname)
      end

      if addresses.empty? || addresses.any? { |address| blocked_address?(address) }
        raise UnsafeUrlError, 'Local, private, and reserved network URLs are not allowed.'
      end

      [uri, addresses]
    rescue URI::InvalidURIError, IPAddr::InvalidAddressError
      raise UnsafeUrlError, 'The URL or its resolved address is invalid.'
    end

    def blocked_address?(address)
      ip = IPAddr.new(address)
      BLOCKED_NETWORKS.any? { |network| network.include?(ip) }
    end
  end

  def initialize
    super('cobblebot')

    @agent.singleton_class.prepend ValidatedFetch
    @agent.http.singleton_class.prepend PinnedConnectionStart
    @agent.user_agent = "CobbleBot version: #{COBBLEBOT_VERSION}"
    @agent.keep_alive = false
    @agent.open_timeout = 5
    @agent.read_timeout = 5
  end
end
