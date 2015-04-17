require 'test_helper'

class IrcBotTest < ActiveSupport::TestCase
  def setup
    Preference.irc_server_host = 'localhost'
    Preference.irc_server_port = 1234
    Preference.irc_enabled = true
  end
  
  def test_list
    bot = IrcBot.new(debug: true)
    bot.list(sender: 'nobody', channel: '#nothing')
  end

  def test_say
    bot = IrcBot.new(debug: true)
    bot.say(sender: {nick: 'nobody'}, message: 'a b c')
  end
end
