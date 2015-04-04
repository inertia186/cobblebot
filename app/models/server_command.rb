require 'rcon/rcon'
require 'cgi'
include ActionView::Helpers::DateHelper

class ServerCommand
  TRY_MAX = 5
  RETRY_SLEEP = 5
  
  cattr_accessor :command_scheme, :rcon, :rcon_connected_at

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
      if @rcon.nil? || @rcon_connected_at.nil? || @rcon_connected_at > 15.minutes.ago
        @rcon = RCON::Minecraft.new(ServerProperties.server_ip, ServerProperties.rcon_port)
        @rcon_connected_at = Time.now
        @rcon_auth_success = nil
      end

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
  
  def self.eval_pattern(pattern, name = nil, options = {})
    eval(pattern, Proc.new {}.binding, name)
  end
  
  def self.eval_command(command, name = nil, options = {})
    eval(command, Proc.new{}.binding, name)
  end
  
  ## Simuates /say
  def self.say(selector, message, options = {color: 'white', as: 'Server'})
    if options[:as].present?
      execute <<-DONE
        tellraw #{selector} [{ "color": "white", "text": "[#{options[:as]}] "}, { "color": "#{options[:color]}", "text": "#{message}" }]
      DONE
    else
      execute <<-DONE
        tellraw #{selector} { "color": "#{options[:color]}", "text": "#{message}" }
      DONE
    end
  end

  ## Simuates /me
  def self.emote(selector, message, options = {color: 'white', as: 'Server'})
    execute <<-DONE
      tellraw #{selector} [{ "color": "white", "text": "* #{options[:as]} "}, { "color": "#{options[:color]}", "text": "#{message}" }]
    DONE
  end

  def self.say_fake_achievement(selector, nick, achievement, hover_text = 'AH YISS', hover_obfuscated = false)
    if nick =~ /herobrine/i
      play_sound('@a', 'heretic_wizsit')
      hover_obfuscated = true
      hover_text ||= 'Scary'
    end
    
    if hover_obfuscated
      # Apparently, even setting "obfuscated: true" in the json will not cause
      # tellraw to make hover text obfuscated.  So, we force it with the old
      # inline strategy originally introduced by Notch.
      hover_text = "§k#{hover_text}§r".force_encoding('US-ASCII')
    end

    execute <<-DONE
      tellraw #{selector} {
        text: "#{nick} has just earned the achievement ", extra: [{
          text: "[#{achievement}]", color: "dark_purple",
          hoverEvent: {
            action: "show_text", value: "#{hover_text}",
            obfuscated: #{hover_obfuscated}
          }
        }]
      }
    DONE
  end

  def self.irc_say(selector, irc_nick, message)
    Rails.logger.info "From IRC: <#{irc_nick}> #{message}"
    
    if Preference.irc_web_chat_enabled?
      execute <<-DONE
        tellraw #{selector} [
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
    player = Player.find_by_nick(nick)
    
    Message::IrcReply.create(body: "<#{nick}> #{message}", author: player)
  end

  def self.irc_event(message)
    Message::IrcReply.create(body: message)
  end

  ## Simuates /tell
  def self.tell(selector, message, options = {as: 'Server'})
    execute <<-DONE
      tellraw #{selector} { "color": "gray", "text":"#{options[:as]} whispers to you: #{message}" }
    DONE
  end

  ## Renders a hyperlink.
  def self.say_link(selector, url, options = {})
    text = url.gsub(/http/i, 'http')
    url = text.split('http')[1]
    return unless url

    url = "http#{url.split(' ')[0]}"
    return unless !!url.split('://')[1]
    
    if !!options[:title]
      url = url
      title = if !!options[:only_title]
        options[:title]
      else
        "#{url.split('/')[2]} :: #{title.strip}"
      end
      last_modified_at = Time.now
    else
      links = Link.expired(false, url)

      if links.any?
        link = links.last
      else
        link = Link.find_or_create_by_url(url)
        link.actor = Player.find_by_nick(options[:nick]) if !!options[:nick]
        link.save
      end
    
      url = link.url
      title = if link.title
        if !!options[:only_title]
          link.title.strip
        else
          "#{link.url.split('/')[2]} :: #{link.title.strip}"
        end
      else
        link.url
      end
      last_modified_at = link.last_modified_at
    end
    
    execute <<-DONE
      tellraw #{selector} { "text": "", "extra": [{
        "text": "#{title}", "color": "dark_purple", "underlined": "true", "hoverEvent": {
          "action": "show_text", "value": "Last Modified: #{last_modified_at ? last_modified_at : '???'}"
        }, "clickEvent": {
          "action": "open_url", "value": "#{url}"
        }
      }]}
    DONE
  end
  
  def self.say_lmgtfy_link(selector, query)
    q = URI.encode_www_form([ ["q", query] ])
    generate_lmgtfy_url = "http://lmgtfy.com/?#{q}"
    base_url = "http://is.gd/create.php?format=json&url="
    is_gd_request_url = URI.parse(base_url + generate_lmgtfy_url)
    url = JSON.parse(Net::HTTP.get_response(is_gd_request_url).body).fetch("shorturl")
    
    say_link selector, url, title: query, only_title: true
  end
  
  def self.tell_motd(selector)
    return unless !!Preference.motd
    results = []
    
    results << execute(
    <<-DONE
      tellraw #{selector} { "text": "Message of the Day", "color": "green" }
    DONE
    )
    results << execute(
    <<-DONE
      tellraw #{selector} { "text": "===", "color": "green" }
    DONE
    )

    Preference.motd.split("\n").each do |line|
      line = line.gsub(/\r/, '')
      if line =~ /^http.*/i
        results << say_link(selector, line, only_title: true)
      else
        results << execute(
        <<-DONE
          tellraw #{selector} { "text": "#{line}", "color": "green" }
        DONE
        )
      end
    end
  end
  
  def self.play_sound(selector, sound, options = {volume: '', pitch: ''})
    execute "execute #{selector} ~ ~ ~ playsound #{sound} @p ~0 ~0 ~0 #{options[:volume]} #{options[:pitch]}"
  end

  def self.tp(selector, destination, options = {})
    execute "tp #{selector} #{destination}" unless !!options[:pretend]
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

  def self.say_playercheck(selector, nick)
    players = Player.any_nick(nick).order(:nick)
    results = []
    
    if players.any?
      player = players.first
      
      results << execute(
      <<-DONE
        tellraw #{selector} [
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
      )
      if !!player.last_chat
        results << say(selector, "<#{player.nick}> #{player.last_chat}#{player.registered? ? ' ®' : ''}")
      end
      results << say(selector, "Biomes explored: #{player.explore_all_biome_progress}")
      # TODO get rate:
      # say selector, "Sum of all trust: ..."
    else
      results << say(selector, "Player not found: #{nick}")
      players = Player.search_any_nick(nick)
      results << say(selector, "Did you mean: #{players.first.nick}") if players.any?
    end
    
    results
  end
  
  def self.say_rules(selector)
    return unless (lines = Preference.rules_json).present?
    
    lines.split("\n").each do |line|
      execute "tellraw #{selector} #{line}"
    end
  end
  
  def self.say_tutorial(selector)
    return unless (lines = Preference.tutorial_json).present?
    
    lines.split("\n").each do |line|
      execute "tellraw #{selector} #{line}"
    end
  end
  
  def self.kick(nick, reason = "Have A Nice Day")
    execute "kick #{nick} #{reason}"
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
  
  def self.add_tip(nick, tip)
    return tell(nick, 'Tip not added.  Nice try.') if tip =~ /@@/
    return tell(nick, 'Tip not added.  Entity selector no longer supported.') if tip =~ /@e/
    return tell(nick, 'Tip not added.  Sheez, do you know how annoying that selector would be?') if tip =~ /@a/
    return tell(nick, 'Tip not added.  Similar tip exists.') if Message::Tip.where("lower(messages.body) LIKE ?", "%#{tip.downcase}%").any?
    
    author = Player.any_nick(nick).first
    _tip = Message::Tip.new(body: tip, author: author)
    
    if _tip.save
      tell(nick, 'Tip added, thank you.')
    else
      tell(nick, "Tip not added.")
    end
  end
  
  def self.escape(message)
    message.gsub(/"/, "\"").force_encoding('US-ASCII')
  end
  
  def self.say_random_tip(selector, nick, keywords = '')
    @no_tips ||= 0
    keywords = keywords.split(' ').map(&:strip)
    
    tip = Message::Tip.query(keywords).in_cooldown(false).sample
    
    if !!tip
      tip_body = escape(tip.body.dup)
      tip_body.sub!(/@r/, Server.players.sample.nick) while tip_body =~ /@r/
      tip_body.sub!(/@p/, Server.players.sample.nick) while tip_body =~ /@p/
      tip_body.sub!(/@e\[c=-1\]/, 'Spy Chicken') while tip_body =~ /@e\[c=-1\]/
      tip_body.sub!(/@e\[c=1\]/, 'Spy Chicken') while tip_body =~ /@e\[c=1\]/
      tip_body.sub!(/@e/, 'Spy Chicken') while tip_body =~ /@e/
      tip.update_attribute(:read_at, Time.now) # set cooldown
      if tip_body =~ /^server/i
        emote('@a', tip_body.split(' ')[1..-1].join(' '))
      elsif tip_body =~ /^herobrine/i
        say_fake_achievement('@a', 'Herobrine', tip_body)
      elsif tip_body =~ /^slap/i
        emote "@a", McSlap.slap(tip_body.split(' ')[1..-1].join(' '))
      elsif tip_body =~ /^>/i
        say(selector, tip_body, color: 'green', as: 'Server')
      else
        say(selector, tip_body)
      end
      
      # FIXME Doing the simulate_server_message is a security risk until the
      # pretend flag can be enabled.  For now, just do simlated_player_chat
      # only.
      #
      # result = MinecraftServerLogHandler.simulate_server_message(tip_body)
      # result = MinecraftServerLogHandler.simulate_player_chat(nick, tip_body) unless !!result
      MinecraftServerLogHandler.simulate_player_chat(nick, tip_body)
    else
      @no_tips += 1
      if @no_tips < 3
        say(selector, 'I got nothin.')
      else
        say(selector, 'I still got nothin.')
        @no_tips = 0
      end
    end
  end
  
  def self.tips
    tips = Message::Tip.all
    tips_in_cooldown = Message::Tip.in_cooldown
    
    say('@a', "There are currently #{tips.count} tips.  In cooldown: #{tips_in_cooldown.count}")
  end
end