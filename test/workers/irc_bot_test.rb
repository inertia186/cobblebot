require 'test_helper'

class IrcBotTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
    Preference.irc_server_host = 'localhost'
    Preference.irc_server_port = 1234
    Preference.irc_enabled = true
    
    @bot = IrcBot.new(debug: true, throttle: 0)
    @bot.load_config
  end

  def test_perform
    assert_same IrcBot, IrcBot.perform
    assert_same IrcBot, IrcBot.perform('start_irc_bot' => true, debug: true)
    assert_raises(NoMethodError) do
      IrcBot.perform('start_irc_bot' => true, debug: false)
    end
  end
  
  def test_opself
    assert_nil @bot.opself
  end

  def test_opme
    assert_nil @bot.opme(sender: {nick: 'nobody'})
  end

  def test_quit_irc
    assert_nil @bot.quit_irc
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
end

module Summer
  class Connection
    def response(message)
    end
  end
end
