require 'test/unit'
require 'CobbleBot'
require 'yaml'
require 'rubygems'
require 'minecraft-query'

class CobbleBotTest < Test::Unit::TestCase
  
  def test_server_started?
    cobblebot_config = CobbleBot::Config.new(config_yaml: "../config/cobblebot.yml")
    server_properties = cobblebot_config.server_properties

    assert server_properties['server-port'], "expected server-port"
    
    query = Query::simpleQuery(server_properties['server-ip'], server_properties['server-port'])
    assert_not_nil query
    assert_nothing_raised(Exception) { query }
    assert_nothing_thrown { query }
    assert_not_nil query[:motd]
  end
  
end