require 'test_helper'
require 'minitest/mock'
require 'tmpdir'

class ServerCommandTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
    ServerProperties.reset_vars
  end

  def test_say
    assert_command_executed do
      ServerCommand.say('@a', 'This is Server.')
    end
  end

  def test_execute_strips_surrounding_command_whitespace
    commands = []
    rcon = Object.new
    rcon.define_singleton_method(:command) do |command|
      commands << command
      ''
    end

    ServerCommand.stub(:command_scheme, 'rcon') do
      ServerCommand.stub(:rcon, rcon) do
        ServerCommand.execute("\n  tellraw @a {\"text\":\"test\"}\n", try_max: 1)
      end
    end

    assert_equal ['tellraw @a {"text":"test"}'], commands
  end

  def test_execute_resolves_rcon_once_per_attempt
    calls = 0
    commands = []
    connection = Object.new
    connection.define_singleton_method(:command) { |command| commands << command; "ran #{command}" }

    ServerCommand.stub(:command_scheme, 'rcon') do
      ServerCommand.stub(:rcon, -> { calls += 1; connection }) do
        assert ServerCommand.execute('list', try_max: 1)
      end
    end

    assert_equal 1, calls
    assert_equal ['list'], commands
  end

  def test_rcon_reuses_fresh_connections_and_replaces_stale_connections
    connections = []
    factory = lambda do |*|
      connection = Object.new
      connection.define_singleton_method(:auth_calls) { @auth_calls.to_i }
      connection.define_singleton_method(:auth) do |*|
        @auth_calls = auth_calls + 1
        true
      end
      connections << connection
      connection
    end

    ServerCommand.reset_vars
    RCON::Minecraft.stub(:new, factory) do
      first = ServerCommand.rcon
      assert_same first, ServerCommand.rcon
      assert_equal 1, connections.size
      assert_equal 1, first.auth_calls

      ServerCommand.instance_variable_set(:@rcon_connected_at, 16.minutes.ago)
      refute_same first, ServerCommand.rcon
      assert_equal 2, connections.size
    end
  ensure
    ServerCommand.reset_vars
  end

  def test_say_anonymous
    assert_command_executed do
      ServerCommand.say('@a', 'This is anonymous.', color: 'white', as: nil)
    end
  end

  def test_say_slap_with_target
    McSlap.stub(:slap, 'slaps Dinnerbone with a large piece of cobble') do
      assert_command_executed do
        ServerCommand.say_slap('@a', 'Server', 'Dinnerbone')
      end
    end

    assert_equal 1, ServerCommand.commands_executed.size
    command = ServerCommand.commands_executed.keys.first
    assert_includes command, 'slaps Dinnerbone with a large piece of cobble'
  end

  def test_say_slap_without_target
    assert_no_difference -> { Link.count } do
      assert_command_executed do
        ServerCommand.say_slap('@a', 'Server')
      end
    end

    assert_equal 1, ServerCommand.commands_executed.size
    command = ServerCommand.commands_executed.keys.first
    assert_includes command, 'has 46116 slap combinations.'
    refute_includes command, 'gist.github.com'
  end

  def test_say_link
    cobblebot = Link.where(url: 'http://github.com/inertia186/cobblebot').first
    cobblebot.update_attribute(:expires_at, 2.days.from_now)

    assert_no_difference -> { Link.count }, 'did not expect new link record' do
      assert_command_executed do
        ServerCommand.say_link '@a', 'http://github.com/inertia186/cobblebot'
      end
    end

    commands = ServerCommand.commands_executed
    payload = JSON.parse(commands.keys.last.match(/\Atellraw @a (.+)\z/m)[1])
    assert_equal 'github.com :: inertia186/cobblebot - GitHub',
      payload.fetch('extra').first.fetch('text')
  end

  def test_say_link_uses_an_explicit_title_with_the_host_prefix
    command = nil

    ServerCommand.stub(:execute, ->(value, *) { command = value }) do
      result = ServerCommand.say_link('@a', 'https://example.com/path', title: ' Example ')

      assert_equal 'https://example.com/path', result[0]
      assert_equal 'example.com :: Example', result[1]
    end

    assert_includes command, 'example.com :: Example'
  end

  def test_say_link_json_encodes_an_explicit_title
    title = "quoted \"title\" with backslash \\"
    command = nil

    ServerCommand.stub(:execute, ->(value, *) { command = value }) do
      ServerCommand.say_link('@a', 'https://example.com/path', title: title, only_title: true)
    end

    payload = JSON.parse(command.match(/\Atellraw @a (.+)\z/m)[1])
    assert_equal title, payload.fetch('extra').first.fetch('text')
  end

  def test_tellraw_entry_points_json_encode_dynamic_text
    message = "quoted: \"hello\"\nsecond line"
    invocations = {
      say: -> { ServerCommand.say('@a', message, color: 'white', as: 'Server') },
      tell: -> { ServerCommand.tell('inertia186', message, as: 'Server') },
      emote: -> { ServerCommand.emote('@a', message, color: 'white', as: 'Server') },
      achievement: -> { ServerCommand.say_fake_achievement('@a', 'inertia186', message) },
      irc_say: -> { ServerCommand.irc_say('inertia186', 'irc-user', message) }
    }
    collect_strings = lambda do |value|
      case value
      when Hash then value.values.flat_map { |item| collect_strings.call(item) }
      when Array then value.flat_map { |item| collect_strings.call(item) }
      when String then [value]
      else []
      end
    end

    invocations.each do |name, invocation|
      command = nil
      ServerCommand.stub(:execute, ->(value, *) { command = value }) { invocation.call }

      match = command.match(/\Atellraw (\S+) (.+)\z/m)
      assert match, "expected a tellraw command for #{name}"
      payload = JSON.parse(match[2])
      assert collect_strings.call(payload).any? { |text| text.include?(message) },
        "expected encoded text for #{name}"
    end
  end

  def test_tellraw_rejects_command_injection_through_the_selector
    assert_raises(CobbleBotError) do
      ServerCommand.say("@a\nsay injected", 'hello')
    end
  end

  def test_secondary_tellraw_renderers_json_encode_database_text
    message = "stored \"quote\" and backslash \\ text"
    inertia = players(:inertia186)
    author = players(:Dinnerbone)
    inertia.messages.create!(body: message, author: author, recipient_term: '@inertia186')
    Message::Topic.create!(body: message, author: author, recipient_term: '@a')
    pvp = messages(:dinnerbone_killed_resnullius)
    pvp.update!(body: message, created_at: 1.minute.from_now)
    Preference.motd = message

    invocations = {
      motd: -> { ServerCommand.tell_motd('inertia186') },
      mail: -> { ServerCommand.tell_mail('inertia186') },
      topic: -> { ServerCommand.tell_topic('inertia186') },
      pvp: -> { ServerCommand.say_last_pvp('@a') }
    }

    invocations.each do |name, invocation|
      commands = []
      ServerCommand.stub(:execute, ->(value, *) { commands << value }) { invocation.call }
      payloads = commands.filter_map do |command|
        match = command.match(/\Atellraw \S+ (.+)\z/m)
        JSON.parse(match[1]) if match
      end

      refute_empty payloads, "expected tellraw output for #{name}"
      assert payloads.any? { |payload| payload.to_s.include?('stored') },
        "expected stored text in #{name} payload: #{payloads.inspect}"
    end
  end

  def test_irc_say_preserves_private_selector_without_web_chat_metadata
    Preference.irc_web_chat_enabled = false
    command = nil

    ServerCommand.stub(:execute, ->(value, *) { command = value }) do
      ServerCommand.irc_say('inertia186', 'irc-user', 'private text')
    end

    assert_match(/\Atellraw inertia186 /, command)
    refute_match(/\Atellraw @a /, command)
  end

  def test_named_sound_target_is_preserved_or_suppressed_by_player_preference
    steve = Struct.new(:nick).new('Steve')
    alex = Struct.new(:nick).new('Alex')
    online = Object.new
    online.define_singleton_method(:none?) { false }
    command = nil

    online.define_singleton_method(:play_sounds) { |*| [alex] }
    Server.stub(:players, online) do
      ServerCommand.stub(:execute, ->(value, *) { command = value }) do
        ServerCommand.play_sound('Steve', 'mailsound')
      end
    end
    assert_match(/\Aexecute Steve /, command)

    command = nil
    online.define_singleton_method(:play_sounds) { |*| [steve] }
    Server.stub(:players, online) do
      ServerCommand.stub(:execute, ->(value, *) { command = value }) do
        assert_nil ServerCommand.play_sound('Steve', 'mailsound')
      end
    end
    assert_nil command
  end

  def test_detect_trouble_entities_queries_each_entity_type_once
    selectors = []
    ServerCommand.detectable_reset

    Server.stub(:entity_data, ->(selector:) { selectors << selector; [] }) do
      assert_equal [], ServerCommand.detect_trouble_entities
    end

    expected = Detectable::TROUBLE_ENTITIES.map(&:first).uniq.map { |type| "@e[type=#{type}]" }
    assert_equal expected, selectors
  ensure
    ServerCommand.detectable_reset
  end

  def test_log_tail_reader_returns_only_the_requested_final_lines
    Dir.mktmpdir do |directory|
      path = File.join(directory, 'latest.log')
      File.write(path, (1..100).map { |number| "line #{number}\n" }.join)

      lines = ServerCommand.send(:tail_lines, path, 50)

      assert_equal 50, lines.size
      assert_equal "line 51\n", lines.first
      assert_equal "line 100\n", lines.last
    end
  end

  def test_say_trust_returns_after_missing_player_lookup
    assert_nil ServerCommand.say_trust('@a', 'no_such_truster_zzzz', 'no_such_trustee_zzzz')
  end

  # TODO
  def test_say_rules
    assert_command_executed do
      ServerCommand.say_rules 'inertia186'
    end

    commands = ServerCommand.commands_executed
    assert_equal 8, commands.size, 'expect eight commands'
    assert commands.keys.first =~ %r(Server Rules), 'expect correct rules'
    assert commands.keys.second =~ %r(===), 'expect correct rules'
    assert commands.keys.last =~ %r(random tip), 'expect correct rules'
  end

  def test_say_tutorial
    assert_command_executed do
      ServerCommand.say_tutorial 'inertia186'
    end

    commands = ServerCommand.commands_executed
    assert_equal 1, commands.size, 'expect one command'
    assert commands.keys.first =~ %r(Don't die.), 'expect correct tutorial'
  end

  def test_say_playercheck
    assert_command_executed do
      ServerCommand.say_playercheck '@a', 'inertia186'
    end

    commands = ServerCommand.commands_executed
    assert_equal 4, commands.size, 'expect three commands'
    assert commands.keys.first =~ %r(Latest activity for inertia186 was), 'expect correct player name'
    assert commands.keys.second =~ %r("<inertia186> Normal Tuesday night for Shia Labeouf. ®"), 'expect correct player last chat'
    assert commands.keys.third =~ %r(Biomes explored: 8), 'expect correct player biome info'
    # TODO check trust

    assert_command_executed do
      ServerCommand.say_playercheck '@a', 'Dinnerbone'
    end

    commands = ServerCommand.commands_executed
    assert_equal 3, commands.size, 'expect two commands'
    assert commands.keys.first =~ %r(Latest activity for Dinnerbone was), 'expect correct player name'
    assert commands.keys.second =~ %r(Biomes explored: 0), 'expect correct player biome info'
    # TODO check trust

    assert_command_executed do
      ServerCommand.say_playercheck '@a', 'inertia'
    end

    commands = ServerCommand.commands_executed
    assert_equal 2, commands.size, 'expect two commands'
    assert commands.keys.first =~ %r("Player not found: inertia"), 'expect no player found'
    assert commands.keys.last =~ %r("@server playercheck inertia186"), "expect suggestion, got: #{commands.keys.last}"
  end

  def test_say_playercheck_switcheroo
    inertia186 = Player.find_by_nick 'inertia186'
    dinnerbone = Player.find_by_nick 'Dinnerbone'

    inertia186.nick = 'temp'
    inertia186.save
    dinnerbone.nick = 'inertia186'
    dinnerbone.save
    inertia186.nick = 'Dinnerbone'
    inertia186.save
    inertia186.last_nick = 'inertia186'
    inertia186.save

    assert_equal 'Dinnerbone', inertia186.nick
    assert_equal 'inertia186', inertia186.last_nick
    assert_equal 'inertia186', dinnerbone.nick
    assert_equal 'Dinnerbone', dinnerbone.last_nick

    assert_command_executed do
      ServerCommand.say_playercheck '@a', 'inertia186'
    end

    commands = ServerCommand.commands_executed
    assert_equal 3, commands.size, 'expect three commands'
    assert commands.keys.first =~ %r(Latest activity for inertia186 was), 'expect correct player name'
    assert commands.keys.second =~ %r(Biomes explored: 0), 'expect correct player biome info'
    # TODO check trust

    assert_command_executed do
      ServerCommand.say_playercheck '@a', 'Dinnerbone'
    end

    commands = ServerCommand.commands_executed
    assert_equal 4, commands.size, 'expect three commands'
    assert commands.keys.first =~ %r(Latest activity for Dinnerbone was), 'expect correct player name'
    assert commands.keys.second =~ %r("<Dinnerbone> Normal Tuesday night for Shia Labeouf. ®"), 'expect correct player last chat (note: player should remain registered)'
    assert commands.keys.third =~ %r(Biomes explored: 8), 'expect correct player biome info'
    # TODO check trust

    assert_command_executed do
      ServerCommand.say_playercheck '@a', 'inertia'
    end

    commands = ServerCommand.commands_executed
    assert_equal 2, commands.size, 'expect two commands'
    assert commands.keys.first =~ %r("Player not found: inertia"), 'expect no player found'
    assert commands.keys.last =~ %r("@server playercheck Dinnerbone"), "expect suggestion, got: #{commands.keys.last}"
  end

  def test_say_origin
    assert_command_executed do
      ServerCommand.say_origin '@a', 'inertia186'
    end
  end

  def test_kick
    assert_command_executed do
      assert_kicked 'jackass186' do
        ServerCommand.kick 'jackass186'
      end
    end

    commands = ServerCommand.commands_executed
    assert_equal 1, commands.size, 'expect one command'
    assert_equal commands.keys.last, 'kick jackass186 Have A Nice Day', 'expect player kick'
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
    player = Struct.new(:nick).new('OnlyPlayer')

    Server.stub(:players, [player]) do
      assert_equal 'OnlyPlayer', ServerCommand.random_nick
    end
  end

  def test_all_nicks
    players = [Struct.new(:nick).new('Alice'), Struct.new(:nick).new('Bob')]

    Server.stub(:players, players) do
      assert_equal %w(Alice Bob), ServerCommand.all_nicks
    end
  end

  def test_find_latest_chat_by_nick
    refute_nil ServerCommand.find_latest_chat_by_nick('inertia186'), 'expect latest chat'
  end

  def test_find_latest_chat_treats_nick_and_content_as_literal_text
    Dir.mktmpdir do |directory|
      logs = File.join(directory, 'logs')
      FileUtils.mkdir_p(logs)
      Preference.path_to_server = directory
      File.write(
        File.join(logs, 'latest.log'),
        "[00:00:00] [Server thread/INFO]: <Regex[Kid]> literal (value)+.\n"
      )

      assert_equal 'literal (value)+.',
        ServerCommand.find_latest_chat_by_nick('Regex[Kid]', '(value)+.')
      assert_nil ServerCommand.find_latest_chat_by_nick('Regex.Kid', '(value)+.')
    end
  end

  def test_command_scheme
    Preference.command_scheme = 'multiplexor'
    ServerCommand.reset_vars

    assert_command_executed do
      ServerCommand.execute('list') # FIXME 'expect command scheme to be unsupported'
    end

    Preference.command_scheme = 'unsupported'
    ServerCommand.reset_vars

    assert_command_executed do
      ServerCommand.execute('list') # FIXME 'expect command scheme to be unsupported'
    end
  end

  def test_eval_command_with_options
    assert ServerCommand.eval_command('options[:element] == 2', 'command_name', {element: 1 + 1}), 'expect options evaluated'
  end

  def test_send_mail
    inertia186 = Player.find_by_nick 'inertia186'

    assert_command_executed do
      assert_difference -> { inertia186.reload.messages.count }, 1, 'expect new message' do
        ServerCommand.send_mail('Dinnerbone', 'inertia186', 'test message')
      end
    end
  end

  def test_tell_mail
    inertia186 = Player.find_by_nick 'inertia186'
    inertia186.messages.create(body: 'test message', recipient_term: '@inertia186')

    assert_command_executed do
      assert_difference -> { inertia186.messages.read.count }, 1, 'expect read message' do
        ServerCommand.tell_mail('inertia186')
      end
    end
  end
end
