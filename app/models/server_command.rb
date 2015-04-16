require 'cgi'
include ActionView::Helpers::DateHelper

class ServerCommand
  include Commandable
  include Sayable
  include Audible
  include Achievable
  include Detectable
  include Linkable
  include Tellable
  include Emotable
  include Teleportable
  include Relayable

  def self.eval_pattern(pattern, name = nil, options = {})
    eval(pattern, Proc.new {}.binding, name)
  end
  
  def self.eval_command(command, name = nil, options = {})
    eval(command, Proc.new{}.binding, name)
  end
  
  def self.player_authenticated(nick, uuid)
    return if nick.to_s.empty? || uuid.to_s.empty?
    
    player = Player.find_by_uuid(uuid)
    
    if player.nil?
      player = Player.create(uuid: uuid, nick: nick, last_login_at: Time.now)
    else
      if player.nick != nick
        player.update_attributes(nick: nick, last_nick: player.nick, last_login_at: Time.now)
      else
        player.update_attributes(nick: nick, last_login_at: Time.now)
      end
    end
    
    player
  end
  
  def self.update_player_last_chat(nick, message, options = {})
    return if !!options[:pretend]
    player = Player.find_by_nick(nick)
    return unless !!player
    
    player.update_attribute(:last_chat, message) # no AR callbacks
    
    player
  end

  def self.update_player_last_ip(nick, ip)
    player = Player.find_by_nick(nick)
    return unless !!player
    
    player.update_attribute(:last_ip, ip) # no AR callbacks
    
    player
  end

  def self.touch_player_last_logged_out(nick)
    player = Player.find_by_nick(nick)
    return unless !!player
    
    player.update_attribute(:last_logout_at, Time.now) # no AR callbacks
    
    player
  end

  def self.random_nick
    Server.players.sample.nick if Server.players.any?
  end

  def self.all_nicks
    Server.players.map(&:nick)
  end
  
  def self.find_latest_chat_by_nick(nick, containing = nil)
    server_log = "#{ServerProperties.path_to_server}/logs/latest.log"
    lines = IO.readlines(server_log)
    return if lines.nil?

    if !!containing
      lines.reject! { |line| line =~ %r(: \<#{nick}\> .*%s*)i }
      line = lines.select { |line| line =~ %r(: \<#{nick}\> .*#{containing}.*)i }.last
    else
      line = lines.select { |line| line =~ %r(: \<#{nick}\> .*)i }.last
    end
    
    line.split(' ')[4..-1].join(' ') unless line.nil?
  end
end