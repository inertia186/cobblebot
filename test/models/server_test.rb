require 'test_helper'
require 'minitest/mock'

class ServerTest < ActiveSupport::TestCase
  class StubRcon
    attr_reader :commands

    def initialize(responses)
      @responses = responses
      @commands = []
    end

    def auth(*)
      true
    end

    def command(command)
      @commands << command
      @responses.shift || @responses.last
    end

    def disconnect
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
end
