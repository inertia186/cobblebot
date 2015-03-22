require 'test_helper'

class ServerCommandTest < ActiveSupport::TestCase
  def setup
    sym = :create!; eval File.read "#{Rails.root}/db/seeds.rb"
    
    TestServerCommand.commands_executed = nil
  end

  def test_say_link
    cobblebot = Link.where(url: 'http://github.com/inertia186/cobblebot').first
    cobblebot.update_attribute(:expires_at, 2.days.from_now)
    
    assert_no_difference -> { Link.count }, 'did not expect new link record' do
      TestServerCommand.say_link '@a', 'http://github.com/inertia186/cobblebot'
    end
    
    commands = TestServerCommand.commands_executed
    assert_equal 1, commands.size, 'expect one command'
    assert commands.last =~ %r("github.com :: inertia186/cobblebot - GitHub", "color"), 'expect full title'
  end

  # TODO
  # def test_say_rules
  #   TestServerCommand.say_rules 'inertia186'
  #   
  #   commands = TestServerCommand.commands_executed
  #   assert_equal 3, commands.size, 'expect three commands'
  #   assert commands.first =~ %r(Don't do mean things.), 'expect correct rules'
  #   assert commands.second =~ %r(Don't say mean things.), 'expect correct rules'
  #   assert commands.last =~ %r(Have fun.), 'expect correct rules'
  # end
  # 
  # def test_say_tutorial
  #   TestServerCommand.say_tutorial 'inertia186'
  #   
  #   commands = TestServerCommand.commands_executed
  #   assert_equal 1, commands.size, 'expect one command'
  #   assert commands.first =~ %r(Don't die.), 'expect correct tutorial'
  # end

  def test_say_playercheck
    TestServerCommand.say_playercheck '@a', 'inertia186'

    commands = TestServerCommand.commands_executed
    assert_equal 3, commands.size, 'expect three commands'
    assert commands.first =~ %r(Latest activity for inertia186 was), 'expect correct player name'
    assert commands.second =~ %r("<inertia186> Normal Tuesday night for Shia Labeouf."), 'expect correct player last chat'
    assert commands.last =~ %r(Biomes explored: 0), 'expect correct player biome info'
    
    TestServerCommand.commands_executed = nil
    TestServerCommand.say_playercheck '@a', 'Dinnerbone'
    
    commands = TestServerCommand.commands_executed
    assert_equal 2, commands.size, 'expect two commands'
    assert commands.first =~ %r(Latest activity for Dinnerbone was), 'expect correct player name'
    assert commands.last =~ %r(Biomes explored: 0), 'expect correct player biome info'

    TestServerCommand.commands_executed = nil
    TestServerCommand.say_playercheck '@a', 'inertia'
    
    commands = TestServerCommand.commands_executed
    assert_equal 2, commands.size, 'expect two commands'
    assert commands.first =~ %r("Player not found: inertia"), 'expect no player found'
    assert commands.last =~ %r("Did you mean: inertia186"), 'expect suggestion'
  end

  def test_kick
    TestServerCommand.kick 'jackass186'
    
    commands = TestServerCommand.commands_executed
    assert_equal 1, commands.size, 'expect one command'
    assert_equal commands.last, 'kick jackass186 Have A Nice Day', 'expect player kick'
  end
end

class TestServerCommand < ServerCommand
  cattr_accessor :commands_executed
  
  def self.execute(command)
    self.commands_executed ||= []
    
    commands_executed << command
  end
end