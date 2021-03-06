require 'cgi'
include ActionView::Helpers::DateHelper

class ServerCommand
  include Commandable
  include Runnable
  include Sayable
  include Audible
  include Achievable
  include Detectable
  include Linkable
  include Tellable
  include Emotable
  include Teleportable
  include Relayable
  include Trustable

  def self.eval_pattern(pattern, name = nil, options = {})
    begin
      eval(pattern, Proc.new {}.binding, name)
    rescue => e
      raise CobbleBotError.new(message: "pattern: #{pattern}, name: #{name}, options: #{options}", cause: e)
    end
  end

  def self.eval_command(command, name = nil, options = {})
    begin
      eval(command, Proc.new{}.binding, name)
    rescue => e
      raise CobbleBotError.new(message: "command: #{command}, name: #{name}, options: #{options}", cause: e)
    end
  end

  def self.player_authenticated(nick, uuid)
    return if nick.to_s.empty? || uuid.to_s.empty?

    player = Player.find_by_uuid(uuid)

    if player.nil?
      player = Player.create(uuid: uuid, nick: nick, last_login_at: Time.now)
    else
      player.update_attributes(nick: nick, last_login_at: Time.now)
    end

    player
  end

  def self.update_player_last_chat(nick, message, options = {})
    return if !!options[:pretend]
    unless Rails.env == 'test'
      Resque.enqueue(MinecraftWatchdog, operation: 'update_player_quotes', nick: nick, message: message, at: Time.now.to_i)
    end
    player = Player.find_by_nick(nick)
    return unless !!player

    player.update_attributes(last_chat: message, last_chat_at: Time.now)

    player
  end

  def self.update_player_last_ip(nick, address)
    unless Rails.env == 'test'
      Resque.enqueue(MinecraftWatchdog, operation: 'update_player_last_ip', nick: nick, address: address)
    end
  end

  def self.update_player_last_location(nick, x, y, z)
    unless Rails.env == 'test'
      Resque.enqueue(MinecraftWatchdog, operation: 'update_player_last_location', nick: nick, x: x, y: y, z: z)
    end
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

  def self.send_mail(author_nick, recipient_nick, message)
    return if recipient_nick =~ /^server$/i
    return if recipient_nick =~ /^irc$/i
    return if recipient_nick =~ /^cleverbot$/i

    author = Player.find_by_nick author_nick
    return if author.nil?

    Player.best_match_by_nick(recipient_nick, no_match: -> {
      # FIXME The 'command' option should come from the callback record, not hardcoded.
      say_nick_not_found(author_nick, recipient_nick, command: "@%nick% #{message}")
    }) do |recipient|
      similar = recipient.messages.read(false).created_since(24.hours.ago).
        where(author: author).
        where("lower(messages.body) LIKE ?", "%#{message.downcase}%")

      if similar.any?
        return tell(author_nick, "Not sent.  #{pluralize similar.count, 'similar unread message'} from you today.")
      end

      mail = recipient.messages.build(author: author, body: message, recipient_term: "@#{recipient_nick}")

      if mail.save
        tell(author.nick, "Message sent to #{recipient.nick}")
      else
        tell(author.nick, "Message not sent.")
      end
    end
  end

  def self.slack_bot
    @slack_bot = SlackBot.instance
  end
end
