require 'test_helper'

class LinkTest < ActiveSupport::TestCase
  def test_title
    cobblebot = Link.where(url: 'http://github.com/inertia186/cobblebot').first
    cobblebot.update_attribute(:expires_at, 2.days.from_now)
    
    assert_equal cobblebot.title, 'inertia186/cobblebot - GitHub', 'expect title not to expire'
  end

  def test_actor_is_optional
    link = links(:cobblebot)

    assert link.valid?
    assert_nil link.actor
  end

  def test_nil_past_and_future_expiration_agree_with_the_scope
    nil_expiration = links(:cobblebot)
    past_expiration = links(:mit)
    future_expiration = Link.create!(
      url: 'https://8.8.8.8/future',
      title: 'Future',
      expires_at: 1.hour.from_now,
      skip_populate_from_response: true
    )
    nil_expiration.update_columns(expires_at: nil)
    past_expiration.update_columns(expires_at: 1.hour.ago)

    assert nil_expiration.expired?
    assert past_expiration.expired?
    refute future_expiration.expired?
    assert_equal [nil_expiration.id, past_expiration.id].sort,
      Link.expired.where(id: [nil_expiration, past_expiration, future_expiration]).pluck(:id).sort
  end

  def test_get_response_populates_cache_metadata
    url = 'https://public.example/page'
    response_time = Time.utc(2026, 8, 9, 3, 0, 0)
    stub_request(:get, url).to_return(
      status: 200,
      body: '<html><title>Public page</title></html>',
      headers: {
        'Content-Type' => 'text/html',
        'Date' => response_time.httpdate,
        'Cache-Control' => 'max-age=600',
        'Last-Modified' => response_time.httpdate
      }
    )

    CobbleBotAgent.stub(:resolve_addresses, ->(*) { ['93.184.216.34'] }) do
      link = Link.new(url: url)

      assert_equal 'Public page', link.title
      assert_equal response_time, link.last_modified_at
      assert_equal response_time + 600, link.expires_at
    end
  end

  def test_private_url_is_invalid_without_an_outbound_request
    url = 'http://127.0.0.1/private'
    request = stub_request(:get, url)

    link = Link.new(url: url)

    refute link.valid?
    assert_includes link.errors[:url].join, 'not allowed'
    assert_not_requested request
  end

  def test_dns_failure_keeps_a_safe_fallback_title
    url = 'https://public.example/unavailable'
    agent = Object.new
    agent.define_singleton_method(:get) { |_url| raise SocketError, 'dns failure' }

    CobbleBotAgent.stub(:new, agent) do
      link = Link.new(url: url)
      assert_equal url, link.title
    end
  end

  def test_can_embed_uses_the_persisted_value_without_an_outbound_request
    link = links(:cobblebot)
    link.update_columns(can_embed: true)

    CobbleBotAgent.stub(:new, -> { flunk 'cached value must avoid HEAD' }) do
      assert link.reload.can_embed?
    end
  end

  def test_frame_denial_headers_are_not_embeddable_case_insensitively
    page = Struct.new(:response)
    agent = Object.new
    link = links(:cobblebot)

    ['DENY', 'deny', 'SAMEORIGIN'].each do |policy|
      link.update_columns(can_embed: nil)
      agent.define_singleton_method(:head) do |_url|
        page.new({'x-frame-options' => policy})
      end

      CobbleBotAgent.stub(:new, agent) do
        assert_equal false, link.reload.can_embed?, policy
        assert_equal false, link.reload[:can_embed], policy
      end
    end
  end

  def test_get_response_uses_the_same_frame_policy
    url = 'https://public.example/framed'
    stub_request(:get, url).to_return(
      status: 200,
      body: '<html><title>Framed page</title></html>',
      headers: {'X-Frame-Options' => 'DENY'}
    )

    CobbleBotAgent.stub(:resolve_addresses, ->(*) { ['93.184.216.34'] }) do
      link = Link.new(url: url)

      assert_equal false, link.can_embed
    end
  end

  def test_failed_head_fetch_returns_and_persists_false
    agent = Object.new
    error = Mechanize::ResponseCodeError.allocate
    agent.define_singleton_method(:head) { |_url| raise error }
    link = links(:cobblebot)
    link.update_columns(can_embed: nil)

    CobbleBotAgent.stub(:new, agent) do
      assert_equal false, link.reload.can_embed?
      assert_equal false, link.reload[:can_embed]
    end
  end

  def test_cache_control_uses_max_age_and_honors_revalidation_directives
    link = links(:cobblebot)
    response_date = Time.utc(2026, 8, 9, 12, 0, 0)

    assert_equal response_date + 600, link.send(:extract_expires_at, {
      'date' => response_date.httpdate,
      'cache-control' => 'public, max-age=600, stale-while-revalidate=30'
    })
    ['no-cache', 'no-store', 'public'].each do |cache_control|
      assert_equal response_date, link.send(:extract_expires_at, {
        'date' => response_date.httpdate,
        'cache-control' => cache_control
      })
    end
  end
end
