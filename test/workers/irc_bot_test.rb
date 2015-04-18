require 'test_helper'

class IrcBotTest < ActiveSupport::TestCase
  def setup
    Preference.irc_server_host = 'localhost'
    Preference.irc_server_port = 1234
    Preference.irc_enabled = true
    
    @bot = IrcBot.new(debug: true)
    @bot.load_config
  end

  def test_perform
    IrcBot.perform
    IrcBot.perform('start_irc_bot' => true, debug: true)
  end
  
  def test_opself
    @bot.opself
  end

  def test_opme
    @bot.opme(sender: {nick: 'nobody'})
  end

  def test_quit_irc
    @bot.quit_irc
  end

  def test_kick
    @bot.kick(message: 'test')
    @bot.kick(message: 'test test')
    @bot.kick(message: 'test test test')
    @bot.kick(message: 'test test test test')
    @bot.kick(message: 'test test test test test')
  end

  def test_latest
    @bot.latest
  end

  def test_chatlog
    @bot.chatlog
  end

  def test_rcon
    @bot.rcon(sender: {nick: 'nobody'}, message: 'test')
    @bot.rcon(sender: {nick: 'nobody'}, message: 'test test')
    @bot.rcon(sender: {nick: 'nobody'}, message: 'test test test')
    @bot.rcon(sender: {nick: 'nobody'}, message: 'test test test test')
    @bot.rcon(sender: {nick: 'nobody'}, message: 'test test test test test')
    @bot.help(sender: {nick: 'nobody'}, message: '@cobblebot rcon list')
  end

  def test_help
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

  def test_info
    @bot.info(sender: {nick: 'nobody'})
  end

  def test_bancheck
    @bot.bancheck(sender: {nick: 'nobody'}, message: 'test')
    @bot.bancheck(sender: {nick: 'nobody'}, message: 'test test')
    @bot.bancheck(sender: {nick: 'nobody'}, message: 'test test test')
    @bot.bancheck(sender: {nick: 'nobody'}, message: 'test test test test')
    @bot.bancheck(sender: {nick: 'nobody'}, message: 'test test test test test')
    @bot.bancheck(sender: {nick: 'nobody'}, message: '@cobblebot bancheck nobody')
  end

  def test_playercheck
    @bot.playercheck(sender: {nick: 'nobody'}, message: 'test')
    @bot.playercheck(sender: {nick: 'nobody'}, message: 'test test')
    @bot.playercheck(sender: {nick: 'nobody'}, message: 'test test test')
    @bot.playercheck(sender: {nick: 'nobody'}, message: 'test test test test')
    @bot.playercheck(sender: {nick: 'nobody'}, message: 'test test test test test')
    @bot.playercheck(sender: {nick: 'nobody'}, message: '@cobblebot playercheck nobody')
  end

  def test_list
    @bot.list(sender: {nick: 'nobody'}, channel: '#nothing')
    @bot.list(sender: {nick: 'nobody'}, channel: '#nothing', message: '@cobblebot list')
  end

  def test_say
    @bot.say(sender: {nick: 'nobody'}, message: 'test')
    @bot.say(sender: {nick: 'nobody'}, message: '@cobblebot say a b c')
  end
end

module Summer
  class Connection
    def response(message)
    end
  end
end
  