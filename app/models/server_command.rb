require 'rcon/rcon'
include ActionView::Helpers::DateHelper

class ServerCommand
  TRY_MAX = 5
  RETRY_SLEEP = 5
  
  cattr_accessor :command_scheme, :rcon

  def self.try_max
    Rails.env == 'test' ? 1 : TRY_MAX
  end
  
  def self.retry_sleep
    Rails.env == 'test' ? 0 : RETRY_SLEEP
  end
  
  def self.reset_vars
    @command_scheme = nil
    @rcon = nil
    @rcon_auth_success = nil
    @multiplexor = nil
  end
  
  def self.command_scheme
    return @command_scheme unless @command_scheme.nil?
    raise StandardError.new("Preference.command_scheme not initialized properly") if Preference.command_scheme.nil?
    
    @command_scheme ||= Preference.command_scheme
  end
  
  def self.execute(command)
    try_max.times do
      case command_scheme
      when 'rcon'
        return rcon.command(command)
      when 'multiplexor'
        # TODO Something like: `bash -c "screen -p 0 -S minecraft -X eval 'stuff \"#{command}\"\015'"`
        return
      else
        raise StandardError.new("Preference.command_scheme not recognized")
      end
    end
  rescue StandardError => e
    Rails.logger.warn e.inspect
    sleep retry_sleep
    ServerProperties.reset_vars
    reset_vars
  end
  
  def self.rcon
    raise StandardError.new("RCON port not set.  To set, please modify server.properties and change rcon.port=25575") unless ServerProperties.rcon_port
    raise StandardError.new("RCON password not set.  To set, please modify server.properties and change rcon.password=") unless ServerProperties.rcon_password
    raise StandardError.new("RCON is disabled.  To enable rcon, please modify server.properties and change enable-rcon=false to enable-rcon=true and restart server.") unless ServerProperties.enable_rcon == 'true'

    try_max.times do
      @rcon ||= RCON::Minecraft.new(ServerProperties.server_ip, ServerProperties.rcon_port)

      begin
        return @rcon if @rcon_auth_success ||= @rcon.auth(ServerProperties.rcon_password)
      rescue Errno::ECONNREFUSED => e
        Rails.logger.warn e.inspect
        sleep retry_sleep
        ServerProperties.reset_vars
        reset_vars
      end
    end
    
    nil
  end
  
  def self.eval_pattern(pattern)
    eval(pattern)
  end
  
  def self.eval_command(command)
    eval(command)
  end
  
  ## Simuates /say
  def self.say(message)
    execute <<-DONE
      tellraw @a { "color": "white", "text": "[Server] #{message}" }
    DONE
  end

  def self.irc_say(irc_nick, message)
    if Preference.irc_web_chat_enabled?
      execute <<-DONE
        tellraw @a [
          { "color": "white", "text": "[" },
          {
            "color": "gold", "text": "irc", "hoverEvent": {
              "action": "show_text", "value": "#{Preference.irc_web_chat_url_label}"
            }, "clickEvent": {
              "action": "open_url", "value": "#{Preference.irc_web_chat_url}"
            }
          },
          { "color": "white", "text":"] <#{irc_nick}> #{message}" }
        ]
      DONE
    else
      execute <<-DONE
        tellraw @a [
          { "color": "white", "text": "[" },
          { "color": "gold", "text": "irc" },
          { "color": "white", "text": "] <#{irc_nick}> #{message}" }
        ]
      DONE
    end
  end

  def self.irc_reply(nick, message)
    IrcReply.create(body: "<#{nick}> #{message}")
  end

  def self.irc_event(message)
    IrcReply.create(body: message)
  end

  ## Simuates /tell
  def self.tell(nick, message, as = "Server")
    execute <<-DONE
      tellraw #{nick} { "color": "gray", "text":"#{as} whispers to you: #{message}" }
    DONE
  end

  ## Renders a hyperlink.
  def self.link(nick, link, options = {})
    text = link.gsub(/http/i, 'http')
    link = text.split('http')[1]
    return unless link

    link = "http#{link.split(' ')[0]}"
    return unless !!link.split('://')[1]
    
    begin
      agent = Mechanize.new
      agent.keep_alive = false
      agent.open_timeout = 5
      agent.read_timeout = 5
      agent.get link

      title = if agent.page && defined?(agent.page.title) && agent.page.title
        if options[:title_only]
          agent.page.title.strip
        else
          "#{link.split('/')[2]} :: #{agent.page.title.strip}"
        end
      else
        link
      end
    rescue SocketError => e
      Rails.logger.warn "Ignoring link: #{link}" && return
    rescue Net::OpenTimeout => e
      title = link
    rescue Net::HTTP::Persistent::Error => e
      title = link
    rescue StandardError => e
      title = "#{link.split('/')[2]} :: #{e.inspect}"
    end

    original_title = title
    title = title.gsub(/[^a-zA-Z0-9:?&=#@+*, \.\/\"\[\]\(\)]/, '-').truncate(90)
    last_modified = agent.page.response['last-modified']
    Rails.logger.warn "Removed characters from: #{original_title}" if title != original_title # FIXME Remove later.
  
    execute <<-DONE
      tellraw #{nick} {
        "text": "#{title}", "color": "dark_purple", "underlined": "true", "hoverEvent": {
          "action": "show_text", "value": "Last Modified: #{last_modified}"
        }, "clickEvent": {
          "action": "open_url", "value": "#{link}"
        }
      }
    DONE
  end
  
  def self.tell_motd(nick)
    return unless !!Preference.motd
    
    execute <<-DONE
      tellraw #{nick} { "text": "Message of the Day", "color": "green" }
    DONE
    execute <<-DONE
      tellraw #{nick} { "text": "===", "color": "green" }
    DONE

    Preference.motd.split("\n").each do |line|
      line = line.gsub(/\r/, '')
      if line =~ /^http.*/i
        link nick, line, title_only: true
      else
        execute  <<-DONE
          tellraw #{nick} { "text": "#{line}", "color": "green" }
        DONE
      end
    end
  end
  
  def self.play_sound(nick, sound, options = {volume: '', pitch: ''})
    execute "execute #{nick} ~ ~ ~ playsound #{sound} @p ~0 ~0 ~0 #{options[:volume]} #{options[:pitch]}"
  end

  def self.tp(nick, destination)
    execute "tp #{nick} #{destination}"
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
  
  def self.update_player_last_chat(nick, message)
    player = Player.find_by_nick(nick)
    return unless !!player
    
    player.update_attribute(:last_chat, message)
    
    player
  end

  def self.update_player_last_ip(nick, ip)
    player = Player.find_by_nick(nick)
    return unless !!player
    
    player.update_attribute(:last_ip, ip)
    
    player
  end

  def self.touch_player_last_logged_out(nick)
    player = Player.find_by_nick(nick)
    return unless !!player
    
    player.update_attribute(:last_logout_at, Time.now)
    
    player
  end

  def self.say_playercheck(nick)
    players = Player.any_nick(nick).order(:nick)
    
    if players.any?
      player = players.first
      #say "Latest activity for #{player.nick} was #{distance_of_time_in_words_to_now(player.last_activity_at)} ago."
      execute <<-DONE
        tellraw @a [
          { "color": "white", "text": "[Server] Latest activity for #{player.nick} was " },
          {
            "color": "white", "text": "#{distance_of_time_in_words_to_now(player.last_activity_at)}",
            "hoverEvent": {
              "action": "show_text", "value": "#{player.last_activity_at}"
            }
          },
          { "color": "white", "text": " ago." }
        ]
      DONE
      say "<#{player.nick}> #{player.last_chat} #{player.registered? ? '®' : ''}"
      say "Biomes explored: #{player.explore_all_biome_progress}"
      # TODO get rate:
      # say "Sum of all trust: ..."
    else
      say "Player not found: #{nick}"
      players = Player.search_any_nick(nick)
      say "Did you mean: #{players.first.nick}" if players.any?
    end
  end
  
  def self.kick(nick, reason = "Have A Nice Day")
    execute "kick #{nick} #{reason}"
  end
end