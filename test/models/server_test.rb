require 'test_helper'
require 'minitest/mock'

class ServerTest < ActiveSupport::TestCase
  class StubRcon
    attr_reader :commands, :disconnect_calls

    def initialize(responses)
      @responses = responses
      @commands = []
      @disconnect_calls = 0
    end

    def auth(*)
      true
    end

    def command(command)
      @commands << command
      @responses.shift || @responses.last
    end

    def disconnect
      @disconnect_calls += 1
      true
    end
  end

  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_banned_players
    assert Server.banned_players, "expect banned players json"
  end

  def test_banned_ips
    assert Server.banned_ips, "expect banned ips json"
  end

  def test_ops
    assert Server.ops, "expect ops json"
  end

  def test_whitelist
    assert Server.whitelist, "expect whitelist json"
  end

  def test_minecraft_mp_server_requests_use_https
    Preference.mmp_api_key = 'FAKE_API_KEY'
    votes_request = stub_request(
      :get,
      'https://minecraft-mp.com/api/?element=votes&format=json&key=FAKE_API_KEY&object=servers'
    ).to_return(status: 200, body: '[]')
    status_request = stub_request(
      :get,
      'https://minecraft-mp.com/api/?element=detail&key=FAKE_API_KEY&object=servers'
    ).to_return(status: 200, body: '{}')

    assert_equal [], Server.mmp_votes
    assert_equal({}, Server.mmp_status)
    assert_requested votes_request
    assert_requested status_request
  end

  def test_minecraft_mp_rejects_unsuccessful_and_invalid_responses_safely
    Preference.mmp_api_key = 'FAKE_API_KEY'
    stub_request(:get, /minecraft-mp\.com/).to_return(status: 503, body: 'secret')

    error = assert_raises(CobbleBotError) { Server.mmp_votes }
    refute_includes error.message, Preference.mmp_api_key

    stub_request(:get, /minecraft-mp\.com/).to_return(status: 200, body: 'invalid')
    error = assert_raises(CobbleBotError) { Server.mmp_status }
    refute_includes error.message, Preference.mmp_api_key
  end

  def test_entity_data_stops_on_current_empty_command_response
    rcon = StubRcon.new([
      'The data tag did not change: {Dimension:0,Health:20s}',
      "Unknown or incomplete command, see below for error\n<--[HERE]"
    ])

    RCON::Minecraft.stub(:new, rcon) do
      assert_equal ['{Dimension:0,Health:20s}'], Server.entity_data(selector: '@e[type=zombie]')
    end

    assert_equal ['entitydata @e[type=zombie] {}', ''], rcon.commands
  end

  def test_entity_data_bounds_unrecognized_continuation_responses
    responses = ['The data tag did not change: {Dimension:0,Health:20s}'] +
      Array.new(Server::MAX_ENTITY_DATA_RESPONSE_PACKETS, 'continuation')
    rcon = StubRcon.new(responses)

    RCON::Minecraft.stub(:new, rcon) do
      Server.entity_data(selector: '@e[type=zombie]')
    end

    assert_equal Server::MAX_ENTITY_DATA_RESPONSE_PACKETS + 1, rcon.commands.length
  end

  def test_entity_data_disconnects_when_authentication_fails
    rcon = StubRcon.new([])
    failure = RuntimeError.new('authentication failed')
    rcon.define_singleton_method(:auth) { |*| raise failure }

    RCON::Minecraft.stub(:new, rcon) do
      assert_same failure, assert_raises(RuntimeError) {
        Server.entity_data(selector: '@e[type=zombie]')
      }
    end

    assert_equal 1, rcon.disconnect_calls
  end

  def test_entity_data_disconnects_when_the_initial_command_fails
    rcon = StubRcon.new([])
    failure = RuntimeError.new('command failed')
    rcon.define_singleton_method(:command) { |*| raise failure }

    RCON::Minecraft.stub(:new, rcon) do
      assert_same failure, assert_raises(RuntimeError) {
        Server.entity_data(selector: '@e[type=zombie]')
      }
    end

    assert_equal 1, rcon.disconnect_calls
  end

  def test_try_max_falls_back_for_missing_invalid_and_nonpositive_values
    [nil, '', 'invalid', '0', '-2'].each do |value|
      assert_equal Server::TRY_MAX,
        Server.try_max(preference_value: value, test_environment: false)
    end
    assert_equal 3,
      Server.try_max(preference_value: '3', test_environment: false)
  end
end
