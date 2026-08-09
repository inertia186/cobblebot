require 'test_helper'

class CobbleBotAgentTest < ActiveSupport::TestCase
  BLOCKED_URLS = %w[
    ftp://example.com/file
    http://localhost/private
    http://127.0.0.1/private
    http://10.0.0.1/private
    http://100.64.0.1/private
    http://169.254.169.254/latest/meta-data
    http://[::1]/private
    http://[::ffff:127.0.0.1]/private
    http://[fc00::1]/private
  ].freeze

  def test_rejects_non_http_and_non_public_destinations
    BLOCKED_URLS.each do |url|
      assert_raises CobbleBotAgent::UnsafeUrlError, url do
        CobbleBotAgent.validate_url!(url)
      end
    end
  end

  def test_accepts_a_hostname_only_when_all_addresses_are_public
    CobbleBotAgent.stub(:resolve_addresses, ->(*) { ['93.184.216.34'] }) do
      assert_equal 'public.example',
        CobbleBotAgent.validate_url!('https://public.example/page').hostname
    end

    CobbleBotAgent.stub(:resolve_addresses, ->(*) { ['93.184.216.34', '127.0.0.1'] }) do
      assert_raises CobbleBotAgent::UnsafeUrlError do
        CobbleBotAgent.validate_url!('https://public.example/page')
      end
    end
  end

  def test_revalidates_redirect_targets_before_following_them
    public_url = 'https://public.example/start'
    private_url = 'http://127.0.0.1/private'
    public_request = stub_request(:get, public_url).to_return(
      status: 302, headers: { 'Location' => private_url }
    )
    private_request = stub_request(:get, private_url)

    CobbleBotAgent.stub(:resolve_addresses, ->(*) { ['93.184.216.34'] }) do
      assert_raises CobbleBotAgent::UnsafeUrlError do
        CobbleBotAgent.new.get(public_url)
      end
    end

    assert_requested public_request
    assert_not_requested private_request
  end

  def test_pins_the_connection_to_the_validated_address
    url = 'https://public.example/page'
    stub_request(:get, url).to_return(status: 200)

    CobbleBotAgent.stub(:resolve_addresses, ->(*) { ['93.184.216.34'] }) do
      agent = CobbleBotAgent.new
      agent.get(url)

      assert_equal '93.184.216.34',
        agent.agent.http.pinned_address_for(URI.parse(url))
    end
  end

  def test_pinned_connection_start_sets_net_http_ip_without_changing_hostname
    connection_class = Class.new do
      def start(http)
        [http.address, http.ipaddr]
      end

      prepend CobbleBotAgent::PinnedConnectionStart
    end
    connection = connection_class.new
    uri = URI.parse('https://public.example/page')
    http = Net::HTTP.new(uri.hostname, uri.port)
    connection.pin_address(uri, '93.184.216.34')

    assert_equal ['public.example', '93.184.216.34'], connection.start(http)
  end
end
