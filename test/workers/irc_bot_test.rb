require 'test_helper'

class IrcBotTest < ActiveSupport::TestCase
  class ImmediateCommandDispatcher
    attr_reader :sender_keys

    def initialize(status: :accepted)
      @status = status
      @sender_keys = []
      @shutdown = false
    end

    def submit(sender_key)
      @sender_keys << sender_key
      yield if @status == :accepted
      @status
    end

    def shutdown
      @shutdown = true
    end

    def shutdown?
      @shutdown
    end
  end

  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
    Preference.irc_server_host = 'localhost'
    Preference.irc_server_port = 1234
    Preference.irc_enabled = true
    
    @bot = IrcBot.new(debug: true, throttle: 0)
    @bot.load_config
    @dispatcher = ImmediateCommandDispatcher.new
    @bot.command_dispatcher = @dispatcher
    @responses = []
    responses = @responses
    @bot.define_singleton_method(:response) do |message|
      responses << message
      nil
    end
    @bot.define_singleton_method(:puts) { |*| }
  end

  def test_perform_ignores_jobs_without_the_start_flag
    assert_same IrcBot, IrcBot.perform
  end

  def test_perform_honors_serialized_debug_option_without_connecting
    IrcBot.stub(:new, ->(*) { flunk 'debug jobs must not open an IRC connection' }) do
      assert_same IrcBot, IrcBot.perform(
        'start_irc_bot' => true,
        'debug' => true,
        'throttle' => 0.25
      )
    end
  end

  def test_perform_preserves_serialized_options_when_starting
    received = nil

    IrcBot.stub(:new, ->(options) { received = options }) do
      assert_same IrcBot, IrcBot.perform(
        'start_irc_bot' => true,
        'debug' => false,
        'throttle' => 0.25
      )
    end

    assert_equal false, received[:debug]
    assert_equal 0.25, received[:throttle]
  end

  def test_perform_rejects_an_invalid_server_port_before_connecting
    Preference.irc_server_port = 0

    IrcBot.stub(:new, ->(*) { flunk 'invalid IRC settings must not open a connection' }) do
      assert_same IrcBot, IrcBot.perform('start_irc_bot' => true)
    end
  end

  def test_finalize_startup_joins_each_configured_channel_once
    joined = []
    @bot.define_singleton_method(:join) { |channel| joined << channel }

    @bot.finalize_startup

    assert_equal [Preference.irc_channel], joined
  end

  def test_connect_starts_capability_negotiation_before_registration
    tcp = fake_connection
    @bot.define_singleton_method(:server) { 'irc.example.test' }
    @bot.define_singleton_method(:port) { 6697 }

    TCPSocket.stub(:open, tcp) { @bot.connect! }

    assert_equal 'CAP LS 302', @responses.first
    assert_operator @responses.index('CAP LS 302'), :<,
      @responses.index { |message| message.start_with?('USER ') }
    assert_operator @responses.index('CAP LS 302'), :<,
      @responses.index { |message| message.start_with?('NICK ') }
  end

  def test_tls_verification_failure_happens_before_credentials_are_sent
    tcp = fake_connection
    tls = fake_connection
    tls.define_singleton_method(:hostname=) { |hostname| @hostname = hostname }
    tls.define_singleton_method(:hostname) { @hostname }
    tls.define_singleton_method(:connect) { self }
    tls.define_singleton_method(:post_connection_check) do |*|
      raise OpenSSL::SSL::SSLError, 'hostname mismatch'
    end
    context = OpenSSL::SSL::SSLContext.new
    config = @bot.instance_variable_get(:@config)
    config[:use_ssl] = true
    config[:server_password] = 'server-secret'
    @bot.define_singleton_method(:server) { 'irc.example.test' }
    @bot.define_singleton_method(:port) { 6697 }
    @bot.define_singleton_method(:log) { |*| }

    TCPSocket.stub(:open, tcp) do
      OpenSSL::SSL::SSLContext.stub(:new, context) do
        OpenSSL::SSL::SSLSocket.stub(:new, ->(raw, configured_context) {
          assert_same tcp, raw
          assert_same context, configured_context
          tls
        }) do
          @bot.connect!
        end
      end
    end

    assert_equal OpenSSL::SSL::VERIFY_PEER, context.verify_mode
    assert context.cert_store
    assert_equal 'irc.example.test', tls.hostname
    assert_empty @responses
    assert tcp.closed?
    assert_nil @bot.instance_variable_get(:@connection)
  end

  def test_channel_message_denies_a_configured_nick_without_an_authenticated_account
    configure_rcon_dispatch

    Thread.stub(:start, ->(&block) { block.call }) do
      @bot.channel_message(
        {nick: 'trusted-operator'},
        Preference.irc_channel,
        '@cobblebot rcon list'
      )
    end

    assert_empty @rcon_calls
  end

  def test_channel_message_denies_a_configured_nick_with_the_wrong_account
    configure_rcon_dispatch
    enable_identity_tags(
      SummerBot::IRC_ACCOUNT_CAPABILITY,
      'account' => 'impostor-account'
    )

    Thread.stub(:start, ->(&block) { block.call }) do
      @bot.channel_message(
        {nick: 'trusted-operator'},
        Preference.irc_channel,
        '@cobblebot rcon list'
      )
    end

    assert_empty @rcon_calls
  end

  def test_channel_message_dispatches_operator_commands_for_a_verified_account
    configure_rcon_dispatch
    enable_identity_tags(
      SummerBot::IRC_ACCOUNT_CAPABILITY,
      'account' => 'trusted-account'
    )

    Thread.stub(:start, ->(&block) { block.call }) do
      @bot.channel_message(
        {nick: 'any-current-nick'},
        Preference.irc_channel,
        '@cobblebot rcon list'
      )
    end

    assert_equal 1, @rcon_calls.size
    assert_equal 'any-current-nick', @rcon_calls.first[:sender][:nick]
    assert_equal 'irc:trusted-account',
      @rcon_calls.first[:sender][:authenticated_identity]
    assert_equal '@cobblebot rcon list', @rcon_calls.first[:message]
  end

  def test_tagged_privmsg_flows_through_summer_with_its_authenticated_account
    configure_rcon_dispatch
    enabled_capabilities.add(SummerBot::IRC_ACCOUNT_CAPABILITY)

    Thread.stub(:start, ->(&block) { block.call }) do
      @bot.parse(
        '@account=trusted-account :current-nick!user@host ' \
          "PRIVMSG #{Preference.irc_channel} :@cobblebot rcon list"
      )
    end

    assert_equal 1, @rcon_calls.size
    assert_equal 'irc:trusted-account',
      @rcon_calls.first[:sender][:authenticated_identity]
    assert_equal({}, @bot.instance_variable_get(:@current_message_tags))
  end

  def test_private_message_uses_the_same_verified_account_boundary
    configure_rcon_dispatch
    enable_identity_tags(
      SummerBot::IRC_ACCOUNT_CAPABILITY,
      'account' => 'trusted-account'
    )

    Thread.stub(:start, ->(&block) { block.call }) do
      @bot.private_message(
        {nick: 'any-current-nick'},
        @bot.irc_nick,
        'rcon list'
      )
    end

    assert_equal 1, @rcon_calls.size
    assert_equal 'irc:trusted-account',
      @rcon_calls.first[:sender][:authenticated_identity]
    assert_equal ['irc:trusted-account'], @dispatcher.sender_keys
  end

  def test_twitch_operator_commands_require_the_configured_server_user_id
    Preference.irc_nickserv_password = 'oauth:test-token'
    @bot.load_config
    configure_rcon_dispatch(identity: 'twitch:12345678')
    enable_identity_tags(
      SummerBot::TWITCH_TAGS_CAPABILITY,
      'user-id' => '12345678'
    )

    Thread.stub(:start, ->(&block) { block.call }) do
      @bot.channel_message(
        {nick: 'changeable-login'},
        Preference.irc_channel,
        '@cobblebot rcon list'
      )
    end

    assert_equal 1, @rcon_calls.size
    assert_equal 'twitch:12345678',
      @rcon_calls.first[:sender][:authenticated_identity]
  end

  def test_regular_commands_remain_available_without_identity_capabilities
    calls = []
    @bot.op_commands = []
    @bot.commands = %w[help]
    @bot.define_singleton_method(:log) { |*| }
    @bot.define_singleton_method(:help) { |options| calls << options }

    Thread.stub(:start, ->(&block) { block.call }) do
      @bot.channel_message(
        {nick: 'ordinary-user'},
        Preference.irc_channel,
        '@cobblebot help'
      )
    end

    assert_equal 1, calls.size
    assert_nil calls.first[:sender][:authenticated_identity]
    assert_equal ['ordinary-user'], @dispatcher.sender_keys
  end

  def test_channel_and_private_messages_share_the_same_bounded_dispatcher
    configure_rcon_dispatch
    enable_identity_tags(
      SummerBot::IRC_ACCOUNT_CAPABILITY,
      'account' => 'trusted-account'
    )

    @bot.channel_message(
      {nick: 'channel-nick', hostname: 'channel-host'},
      Preference.irc_channel,
      '@cobblebot rcon list'
    )
    @bot.private_message(
      {nick: 'private-nick', hostname: 'private-host'},
      @bot.irc_nick,
      'rcon list'
    )

    assert_equal ['irc:trusted-account', 'irc:trusted-account'],
      @dispatcher.sender_keys
    assert_equal 2, @rcon_calls.size
  end

  def test_rate_key_prefers_authenticated_identity_then_hostmask
    authenticated = {
      nick: 'current-nick',
      hostname: 'user@host',
      authenticated_identity: 'irc:stable-account'
    }
    unauthenticated = authenticated.merge(authenticated_identity: nil)

    assert_equal 'irc:stable-account',
      @bot.send(:command_rate_key, authenticated)
    assert_equal 'current-nick!user@host',
      @bot.send(:command_rate_key, unauthenticated)
  end

  def test_rejected_commands_are_not_executed
    @dispatcher = ImmediateCommandDispatcher.new(status: :queue_full)
    @bot.command_dispatcher = @dispatcher
    configure_rcon_dispatch
    enable_identity_tags(
      SummerBot::IRC_ACCOUNT_CAPABILITY,
      'account' => 'trusted-account'
    )

    @bot.channel_message(
      {nick: 'operator'},
      Preference.irc_channel,
      '@cobblebot rcon list'
    )

    assert_empty @rcon_calls
    assert_equal ['irc:trusted-account'], @dispatcher.sender_keys
  end

  def test_socket_writes_are_serialized
    bot = IrcBot.new(debug: true, throttle: 0)
    bot.load_config
    bot.define_singleton_method(:puts) { |*| }
    mutex = Mutex.new
    active = 0
    maximum_active = 0
    messages = []
    connection = Object.new
    connection.define_singleton_method(:puts) do |message|
      mutex.synchronize do
        active += 1
        maximum_active = [maximum_active, active].max
      end
      sleep 0.02
      messages << message
    ensure
      mutex.synchronize { active -= 1 }
    end
    bot.instance_variable_set(:@connection, connection)

    threads = %w[first second].map do |message|
      Thread.new { bot.response(message) }
    end
    threads.each(&:join)

    assert_equal 1, maximum_active
    assert_equal %w[first second].sort, messages.sort
  ensure
    bot&.shutdown_command_dispatcher
  end

  def test_command_dispatcher_is_shut_down_explicitly
    @bot.shutdown_command_dispatcher

    assert @dispatcher.shutdown?
    assert_nil @bot.instance_variable_get(:@command_dispatcher)
  end

  def test_every_operator_command_uses_the_authenticated_identity_boundary
    Preference.irc_channel_ops = 'irc:trusted-account'
    @bot.op_commands = %w[rcon kick quit_irc]
    verified = {authenticated_identity: 'irc:trusted-account'}
    unverified = {authenticated_identity: nil}

    @bot.op_commands.each do |command|
      assert @bot.send(:valid_op_command?, verified, command), command
      refute @bot.send(:valid_op_command?, unverified, command), command
    end
  end

  def test_ircv3_tags_are_unescaped_and_removed_before_summer_parsing
    tags, message = @bot.send(
      :extract_message_tags,
      '@account=trusted\\saccount;note=semi\\:colon;flag :nick!user@host PRIVMSG #channel :hello'
    )

    assert_equal 'trusted account', tags['account']
    assert_equal 'semi;colon', tags['note']
    assert_nil tags['flag']
    assert_equal ':nick!user@host PRIVMSG #channel :hello', message
  end

  def test_standard_irc_capability_ack_enables_authenticated_accounts
    @bot.parse(":server CAP #{@bot.irc_nick} LS :multi-prefix account-tag")

    assert_includes @responses, 'CAP REQ :account-tag'
    refute_includes @responses, 'CAP END'

    @bot.parse(":server CAP #{@bot.irc_nick} ACK :account-tag")

    assert_includes @responses, 'CAP END'
    assert_includes enabled_capabilities, SummerBot::IRC_ACCOUNT_CAPABILITY
  end

  def test_capability_rejection_leaves_operator_identity_disabled
    @bot.parse(":server CAP #{@bot.irc_nick} LS :account-tag")
    @bot.parse(":server CAP #{@bot.irc_nick} NAK :account-tag")

    assert_includes @responses, 'CAP END'
    refute_includes enabled_capabilities, SummerBot::IRC_ACCOUNT_CAPABILITY
  end

  def test_capability_removal_immediately_revokes_operator_identity
    @bot.parse(":server CAP #{@bot.irc_nick} LS :account-tag")
    @bot.parse(":server CAP #{@bot.irc_nick} ACK :account-tag")
    @bot.parse(":server CAP #{@bot.irc_nick} DEL :account-tag")

    refute_includes enabled_capabilities, SummerBot::IRC_ACCOUNT_CAPABILITY
  end

  def test_twitch_requests_server_tags_during_capability_negotiation
    Preference.irc_nickserv_password = 'oauth:test-token'
    @bot.load_config

    @bot.parse(
      ":server CAP #{@bot.irc_nick} LS :twitch.tv/membership twitch.tv/commands twitch.tv/tags"
    )

    assert_includes @responses,
      'CAP REQ :twitch.tv/membership twitch.tv/commands twitch.tv/tags'
  end
  
  def test_opself
    assert_nil @bot.opself
  end

  def test_opme
    assert_nil @bot.opme(sender: {nick: 'nobody'})
  end

  def test_quit_irc
    @bot.shall_monitor = true
    assert_nil @bot.quit_irc
    refute @bot.shall_monitor
  end

  def test_op_identities_default_to_an_empty_list
    Preference.irc_channel_ops = nil

    assert_equal [], @bot.op_identities
    refute @bot.send(
      :valid_op_command?,
      {nick: 'nobody', authenticated_identity: nil},
      'help'
    )
  end

  def test_startup_identifies_with_the_symbol_key_loaded_from_preferences
    Preference.irc_nickserv_password = 'secret'
    @bot.load_config
    messages = []
    @bot.define_singleton_method(:did_start_up) {}
    @bot.define_singleton_method(:privmsg) { |message, recipient| messages << [message, recipient] }
    @bot.define_singleton_method(:finalize_startup) {}

    thread = Thread.stub(:new, ->(&block) { block.call }) do
      @bot.stub(:sleep, nil) { @bot.startup! }
    end

    assert_nil thread
    assert_equal [['identify secret', 'nickserv']], messages
  end

  def test_kick_event_tracks_the_victim_without_raising
    Preference.active_in_irc = 2
    event = nil

    IrcBot.stub(:irc_say_event, ->(target, message) { event = [target, message] }) do
      @bot.kick_event({nick: 'operator'}, '#channel', 'player', 'reason')
    end

    assert_equal 1, Preference.active_in_irc.to_i
    assert_equal ['@a', 'player was kicked from IRC'], event
  end

  def test_kick_event_ignores_the_bot_itself
    Preference.active_in_irc = 2

    IrcBot.stub(:irc_say_event, ->(*) { flunk 'self-kick must not emit a player event' }) do
      @bot.kick_event({nick: 'operator'}, '#channel', @bot.irc_nick, 'reason')
    end

    assert_equal 2, Preference.active_in_irc.to_i
  end

  def test_kick
    assert_nothing_raised do
      @bot.kick(message: 'test')
      @bot.kick(message: 'test test')
      @bot.kick(message: 'test test test')
      @bot.kick(message: 'test test test test')
      @bot.kick(message: 'test test test test test')
    end
  end

  def test_latest
    assert_nil @bot.latest
  end

  def test_chatlog
    assert_nil @bot.chatlog
  end

  def test_rcon
    assert_nothing_raised do
      @bot.rcon(sender: {nick: 'nobody'}, message: 'test')
      @bot.rcon(sender: {nick: 'nobody'}, message: 'test test')
      @bot.rcon(sender: {nick: 'nobody'}, message: 'test test test')
      @bot.rcon(sender: {nick: 'nobody'}, message: 'test test test test')
      @bot.rcon(sender: {nick: 'nobody'}, message: 'test test test test test')
      @bot.help(sender: {nick: 'nobody'}, message: '@cobblebot rcon list')
    end
  end

  def test_help
    assert_nothing_raised do
      @bot.help(sender: {nick: 'nobody'}, message: 'test')
      @bot.help(sender: {nick: 'nobody'}, message: 'test test')
      @bot.help(sender: {nick: 'nobody'}, message: 'test test test')
      @bot.help(sender: {nick: 'nobody'}, message: 'test test test test')
      @bot.help(sender: {nick: 'nobody'}, message: 'test test test test test')
      @bot.help(sender: {nick: 'nobody'}, message: '@cobblebot help info')
      @bot.help(sender: {nick: 'nobody'}, message: '@cobblebot help bancheck')
      @bot.help(sender: {nick: 'nobody'}, message: '@cobblebot help playercheck')
      @bot.help(sender: {nick: 'nobody'}, message: '@cobblebot help list')
      @bot.help(sender: {nick: 'nobody'}, message: '@cobblebot help say')
    end
  end

  def test_info
    assert_nothing_raised { @bot.info(sender: {nick: 'nobody'}) }
  end

  def test_bancheck
    assert_nothing_raised do
      @bot.bancheck(sender: {nick: 'nobody'}, message: 'test')
      @bot.bancheck(sender: {nick: 'nobody'}, message: 'test test')
      @bot.bancheck(sender: {nick: 'nobody'}, message: 'test test test')
      @bot.bancheck(sender: {nick: 'nobody'}, message: 'test test test test')
      @bot.bancheck(sender: {nick: 'nobody'}, message: 'test test test test test')
      @bot.bancheck(sender: {nick: 'nobody'}, message: '@cobblebot bancheck nobody')
    end
  end

  def test_playercheck
    assert_nothing_raised do
      @bot.playercheck(sender: {nick: 'nobody'}, message: 'test')
      @bot.playercheck(sender: {nick: 'nobody'}, message: 'test test')
      @bot.playercheck(sender: {nick: 'nobody'}, message: 'test test test')
      @bot.playercheck(sender: {nick: 'nobody'}, message: 'test test test test')
      @bot.playercheck(sender: {nick: 'nobody'}, message: 'test test test test test')
      @bot.playercheck(sender: {nick: 'nobody'}, message: '@cobblebot playercheck nobody')
    end
  end

  def test_list
    assert_nothing_raised do
      @bot.list(sender: {nick: 'nobody'}, channel: '#nothing')
      @bot.list(sender: {nick: 'nobody'}, channel: '#nothing', message: '@cobblebot list')
    end
  end

  def test_say
    assert_nothing_raised do
      @bot.say(sender: {nick: 'nobody'}, message: 'test')
      @bot.say(sender: {nick: 'nobody'}, message: '@cobblebot say a b c')
    end
  end

private
  def configure_rcon_dispatch(identity: 'irc:trusted-account')
    Preference.active_in_irc = 1
    Preference.irc_channel_ops = identity
    @bot.op_commands = %w[rcon]
    @bot.commands = []
    @bot.define_singleton_method(:log) { |*| }
    @rcon_calls = []
    calls = @rcon_calls
    @bot.define_singleton_method(:rcon) { |options| calls << options }
  end

  def enable_identity_tags(capability, tags)
    enabled_capabilities.add(capability)
    @bot.instance_variable_set(:@current_message_tags, tags)
  end

  def enabled_capabilities
    @bot.instance_variable_get(:@enabled_capabilities)
  end

  def fake_connection
    Object.new.tap do |connection|
      connection.instance_variable_set(:@closed, false)
      connection.define_singleton_method(:close) { @closed = true }
      connection.define_singleton_method(:closed?) { @closed }
    end
  end
end
