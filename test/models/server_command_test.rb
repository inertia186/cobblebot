require 'test_helper'

class ServerCommandTest < ActiveSupport::TestCase
  def setup
    seed
    
    TestServerCommand.commands_executed = nil
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_say
    refute_nil TestServerCommand.say('@a', 'This is Server.'), 'expect say to work'
  end

  def test_say_anonymous
    refute_nil TestServerCommand.say('@a', 'This is anonymous.', color: 'white', as: nil), 'expect say to work'
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
  def test_say_rules
    TestServerCommand.say_rules 'inertia186'
    
    commands = TestServerCommand.commands_executed
    assert_equal 9, commands.size, 'expect three commands'
    assert commands.first =~ %r(Server Rules), 'expect correct rules'
    assert commands.second =~ %r(===), 'expect correct rules'
    assert commands.last =~ %r(random tip), 'expect correct rules'
  end
  
  def test_say_tutorial
    TestServerCommand.say_tutorial 'inertia186'
    
    commands = TestServerCommand.commands_executed
    assert_equal 1, commands.size, 'expect one command'
    assert commands.first =~ %r(Don't die.), 'expect correct tutorial'
  end

  def test_say_playercheck
    TestServerCommand.say_playercheck '@a', 'inertia186'

    commands = TestServerCommand.commands_executed
    assert_equal 3, commands.size, 'expect three commands'
    assert commands.first =~ %r(Latest activity for inertia186 was), 'expect correct player name'
    assert commands.second =~ %r("<inertia186> Normal Tuesday night for Shia Labeouf."), 'expect correct player last chat'
    assert commands.last =~ %r(Biomes explored: 8), 'expect correct player biome info'
    
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
  
  def test_merge_selectors
    assert_equal '@a', ServerCommand.merge_selectors('@a', '@a')
    assert_equal '@a[r=1]', ServerCommand.merge_selectors('@a[r=1]', '@a')
    assert_equal '@a[r=1]', ServerCommand.merge_selectors('@a', '@a[r=1]')
    assert_equal '@a[r=1,x=2]', ServerCommand.merge_selectors('@a[r=1]', '@a[x=2]')
    assert_equal '@a[r=1,r=2]', ServerCommand.merge_selectors('@a[r=1]', '@a[r=2]')
    assert_equal '@a[score_points_min=30,score_points=39,x=10,y=20,z=30,r=4]', ServerCommand.merge_selectors('@a[score_points_min=30,score_points=39]', '@a[x=10,y=20,z=30,r=4]')
    assert_equal '@e[type=Creeper,c=3,type=Cow]', ServerCommand.merge_selectors('@e[type=Creeper,c=3]', '@e[type=Cow]')
  end
  
  def test_random_nick
    skip "Test is acting up." unless ServerCommand.random_nick.nil?
    
    assert_nil ServerCommand.random_nick, 'did not expect random nick'
  end
  
  def test_all_nicks
    skip "Test is acting up." unless ServerCommand.all_nicks == []
    
    assert_equal [], ServerCommand.all_nicks, 'did not expect all nicks'
  end
  
  def test_find_latest_chat_by_nick
    refute_nil TestServerCommand.find_latest_chat_by_nick('inertia186'), 'expect latest chat'
  end
  
  def test_command_scheme
    Preference.command_scheme = 'multiplexor'
    
    assert_nil ServerCommand.execute('list'), 'expect command scheme to be unsupported'

    ServerCommand.reset_vars
    Preference.command_scheme = 'unsupported'
    
    assert_nil ServerCommand.execute('list'), 'expect command scheme to be unsupported'
  end
end
