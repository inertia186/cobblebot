require 'google_translate'
require 'google_translate/version'
require 'google_translate/result_parser'

module Sayable
  extend Commandable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    ## Simuates /say
    def say(selector, message, options = {color: 'white', as: 'Server'})
      return if selector.nil?
    
      if options[:as].present?
        if !!(hover_text = options[:hover_text]) && hover_text.present?
          execute <<-DONE
            tellraw #{selector} [
              { "color": "white", "text": "[#{options[:as]}] "},
              {
                "color": "#{options[:color]}", "text": "#{message}",
                "hoverEvent": {
                  "action": "show_text", "value": "#{hover_text}"
                }
              }
            ]
          DONE
        else
          execute <<-DONE
            tellraw #{selector} [{ "color": "white", "text": "[#{options[:as]}] "}, { "color": "#{options[:color]}", "text": "#{message}" }]
          DONE
        end
      else
        if !!(hover_text = options[:hover_text]) && hover_text.present?
          execute <<-DONE
            tellraw #{selector} [
              { "color": "white", "text": "[#{options[:as]}] "},
              {
                "color": "#{options[:color]}", "text": "#{message}",
                "hoverEvent": {
                  "action": "show_text", "value": "#{hover_text}"
                }
              }
            ]
          DONE
        else
          execute <<-DONE
            tellraw #{selector} { "color": "#{options[:color]}", "text": "#{message}" }
          DONE
        end
      end
      
      # FIXME Probably need to return a text-only version for logging purposes.
    end
    
    def say_playercheck(selector, nick)
      Player.best_match_by_nick(nick, no_match: -> { 
        # FIXME The 'command' option should come from the callback record, not hardcoded.
        say_nick_not_found(selector, nick, command: '@server playercheck %nick%')
      }) do |player|
        line_1a = "Latest activity for #{player.nick} was "
        line_1b = if player.last_chat_at.nil?
          '???'
        else
          distance_of_time_in_words_to_now(player.last_chat_at)
        end
        line_1c = player.last_chat_at.to_s
        line_1d = ' ago.'
        execute(
        <<-DONE
          tellraw #{selector} [
            { "color": "white", "text": "[Server] #{line_1a}" },
            {
              "color": "white", "text": "#{line_1b}",
              "hoverEvent": {
                "action": "show_text", "value": "#{line_1c}"
              }
            },
            { "color": "white", "text": "#{line_1d}" }
          ]
        DONE
        ) unless selector.nil?
      
        results = ["#{line_1a}#{line_1b}#{line_1d} (#{line_1c})"]
        results += say_last_chat(selector, nick, player: player)
        results += say_biomes_explored(selector, nick, player: player)
        results += say_reputation_sum(selector, nick, player: player)
      
        results
      end
    end
    
    def say_last_chat(selector, nick, options = {})
      player = options[:player]
      player ||= Player.find_by_nick(nick)
      result = nil
      
      if !!player && !!player.last_chat
        result = "<#{player.nick}> #{player.last_chat}#{player.registered? ? ' ®' : ''}"
        say(selector, result)
      end
      
      [result]
    end
    
    def say_biomes_explored(selector, nick, options = {})
      player = options[:player]
      player ||= Player.find_by_nick(nick)
      result = nil

      if !!player
        the_end = player.achievement.explore_all_biomes["progress"].include? 'The End' rescue false
        say(selector, result = "Biomes explored: #{player.explore_all_biome_progress}", color: 'white', as: 'Server', hover_text: the_end ? 'Including The End' : 'Not including The End.')
      end
      
      [result]
    end
    
    def say_reputation_sum(selector, nick, options = {})
      player = options[:player]
      player ||= Player.find_by_nick(nick)
      result = nil

      if !!player
        say(selector, result = "Sum of all trust: #{player.reputations.map(&:rate).sum}", color: 'white', as: 'Server', hover_text: "From #{pluralize(player.reputations.count, 'player')}.")
      end
      
      [result]
    end
    
    def say_nick_not_found(selector, nick, options = {})
      message = options[:message] || 'Player not found'
      results = [line_1 = "#{message}: #{nick}"]
      say(selector, line_1)
      players = Player.search_any_nick(nick)
      if players.any?
        results << line_2 = "Did you mean: #{players.first.nick}"
        if !!selector && !!options[:command]
          cmd = options[:command].gsub("%nick%", players.first.nick)
          execute(
          <<-DONE
            tellraw #{selector} [
              {"color": "white", "text": "[Server] Did you mean: "},
              {
                "color": "dark_purple", "underlined": "true", "text": "#{players.first.nick}",
                "clickEvent": {
                  "action": "suggest_command", "value": "#{cmd}"
                }
              }
            ]
          DONE
          )
        else
          say(selector, line_2)
        end
      end
      
      results
    end
    
    def say_json_preference(selector, key)
      return unless (lines = Preference.send(key)).present?
      return if selector.nil?
    
      lines.split("\n").each do |line|
        execute "tellraw #{selector} #{line}"
      end
    end
    
    def say_rules(selector)
      say_json_preference(selector, :rules_json)
    end
  
    def say_tutorial(selector)
      say_json_preference(selector, :tutorial_json)
    end
    
    def say_faq(selector)
      say_json_preference(selector, :faq_json)
    end
    
    def say_random_tip(selector, nick, keywords = '', options =())
      keywords = keywords.split(' ').map(&:strip)
      tip = nil
      
      if keywords.size == 1 && keywords[0] =~ /\d/
        tip = Message::Tip.order(:id).limit(keywords[0].to_i).last
      elsif keywords.any?
        tip = Message::Tip.query(keywords).in_cooldown(false).first(10).sample
      else
        tip = Message::Tip.query(keywords).in_cooldown(false).sample
      end
      
      if tip.nil?
        tip = Message::Tip.query(keywords).in_cooldown(false).first
      end
      
      return say_nothing(selector) unless !!tip
  
      replies = tip.replies.map(&:body).join("\n").strip
      replies ||= "In reply to: #{tip.parent.body.strip}" if !!tip.parent

      tip_body = sub_safe_selectors(escape(tip.body.dup))
      tip.update_attribute(:read_at, Time.now) # set cooldown, no AR callbacks
      if tip_body =~ /^server/i
        emote(selector, tip_body.split(' ')[1..-1].join(' '), color: 'white', as: 'Server', hover_text: replies)
      elsif tip_body =~ /^herobrine/i
        say_fake_achievement(selector, 'Herobrine', tip_body.split(' ')[1..-1].join(' '), replies || 'AH YISS', true)
      elsif tip_body =~ /^slap/i
        nick = if !!tip.author
          tip.author.nick
        else
          'Server'
        end
        say_slap(selector, nick, tip_body.split(' ')[1..-1].join(' '), hover_text: replies)
      elsif tip_body =~ /^>/i
        say(selector, tip_body, color: 'green', as: 'Server', hover_text: replies)
      elsif tip_body =~ /explode/i
        play_sound(selector, 'random.explode')
        say(selector, tip_body, color: 'white', as: 'Server', hover_text: replies)
      elsif tip_body =~ /there is no place like/i
        play_sound(selector, 'loz_recorder')
        say(selector, tip_body, color: 'white', as: 'Server', hover_text: replies)
      else
        say(selector, tip_body, color: 'white', as: 'Server', hover_text: replies)
      end
    
      # FIXME Doing the simulate_server_message is a security risk until the
      # pretend flag can be enabled.  For now, just do simlated_player_chat
      # only.
      #
      # result = MinecraftServerLogHandler.simulate_server_message(tip_body)
      # result = MinecraftServerLogHandler.simulate_player_chat(nick, tip_body) unless !!result
      n = if !!tip.author && !!tip.author.nick
        tip.author.nick # Try to use the author's nick if present.
      else
        nick # Fall back to the person who asked for the tip.
      end
      MinecraftServerLogHandler.simulate_player_chat(n, tip_body)
    
      tip_body
    rescue ArgumentError => e
      return unless !!tip
      
      Rails.logger.warn "Message::Tip.id: #{tip.id} :: #{e.inspect}"
      tip.update_attribute(:read_at, Time.now)
      say(selector, e.message)
    end
    
    def say_nothing(selector)
      @attempts ||= 0
      
      message = if (@attempts += 1) < 3
        'I got nothin.'
      else
        @attempts = 0
        'I still got nothin.'
      end
      
      say(selector, message)
      
      message
    end
    
    def tips(selector = '@a')
      tips = Message::Tip.all
      tips_in_cooldown = Message::Tip.in_cooldown
    
      say(selector, "There are currently #{tips.count} tips.  In cooldown: #{tips_in_cooldown.count}")
    end
    
    def say_slap(selector = "@a", nick = "Server", target = nil, options = {})
      result = nil
      target = target.strip if !!target
    
      if target.present?
        emote selector, result = McSlap.slap(sub_safe_selectors(target)), color: 'white', as: nick, hover_text: options[:hover_text]
      else
        emote selector, "has #{McSlap.combinations} slap combinations, see:"
        say_link selector, "https://gist.github.com/inertia186/5002463", only_title: true
      end
    
      result
    end
    
    def say_help(selector = "@a", key = "help")
      key = 'help' unless key.present?
      callbacks = ServerCallback.enabled.where('lower(help_doc_key) = ?', key.strip.downcase)
      
      callback = if !!callbacks && callbacks.any?
        callbacks.first
      else
        ServerCallback.where(help_doc_key: 'help').first
      end
      
      callback.help_doc.each_line do |line|
        say selector, line.strip, color: 'white', as: nil
      end
      
      unless callback.cooldown.split(' ')[0] =~ /^\+0/
        say selector, "Note, #{key} has a cooldown interval of #{callback.cooldown}.", color: 'white', as: nil
      end
      
      case callback.help_doc_key
      when 'help'
        topics = []
        ServerCallback.enabled.has_help_docs.order(:help_doc_key).each do |callback|
          topics << callback.help_doc_key
        end
        
        say selector, topics.join(' | '), color: 'white', as: nil if topics.any?
      end
    end
    
    def say_origin(selector, nick)
      Player.best_match_by_nick(nick, no_match: -> {
        # FIXME The 'command' option should come from the callback record, not hardcoded.
        say_nick_not_found(selector, nick, command: '@server origin %nick%')
      }) do |target|
        execute <<-DONE
          tellraw #{selector} [{ "color": "white", "text": "[Server] Origin of #{target.nick}: "}, { "color": "green", "text": "#{target.origins.join(', ')}" }]
        DONE
      end
    end
    
    def say_last_pvp(selector, nick)
      nick = nick.strip
      victim = nil
      no_match = false
      
      if nick == '@p' || nick == '@r'
        nick = Server.player_nicks(nick).first
      elsif nick =~ /@/
        nick = ''
      end
      
      unless nick.empty?
        Player.has_pvp_losses.best_match_by_nick(nick, no_match: -> {
          # FIXME The 'command' option should come from the callback record, not hardcoded.
          say_nick_not_found(selector, nick, command: '@server lastpvp %nick%', message: 'No PVP found for')
          no_match = true
        }) do |target|
          if target.pvp_losses.none?
            say(selector, "No pvp log for: #{target.nick}") and return
          else
            victim = target
          end
        end
      end
      
      return if no_match
      
      pvp = if victim
        victim.pvp_losses
      else
        Message::Pvp.all
      end.order(:created_at).last
      
      say(selector, "No pvp log.") and return if pvp.nil?
      
      body = pvp.body
      
      pvp_log = if (relation = pvp.recipient.pvp_losses.supplementary(pvp)).any?
        "#{body} (x#{relation.count + 1})"
      else
        body
      end
      
      loser_quote = "<#{pvp.recipient.nick}> #{pvp.loser_quote}"
      winner_quote = "<#{pvp.author.nick}> #{pvp.winner_quote}"
      pvp_quotes = if loser_quote == winner_quote
        winner_quote
      else
        "#{loser_quote}\n#{winner_quote}"
      end
      
      execute(
      <<-DONE
        tellraw #{selector} [
          { "color": "white", "text": "[Server] " },
          {
            "color": "white", "text": "#{distance_of_time_in_words_to_now(pvp.created_at)} ago ",
            "hoverEvent": {
              "action": "show_text", "value": "#{pvp.created_at.to_s}"
            }
          },
          {
            "color": "white", "text": "#{pvp_log}",
            "hoverEvent": {
              "action": "show_text", "value": "#{pvp_quotes}"
            }
          }
        ]
      DONE
      ) unless selector.nil?
    end
    
    def say_translation(selector, pair, term)
      pair = pair.split(':')
      if pair.size == 1
        from = :auto
        to = pair[0].to_sym
      else
        from = pair[0].to_sym
        to = pair[1].to_sym
      end
      translator = GoogleTranslate.new
      translation = translator.translate(from, to, term)
      
      say(selector, escape(translation.first.first.first), as: 'Google', color: 'white', hover_text: "Translation from: #{translation.third}")
    end
    
    def say_trust(selector, truster_nick, trustee_nick)
      truster = nil
      trustee = nil
      
      Player.best_match_by_nick(truster_nick, no_match: -> {
        # FIXME The 'command' option should come from the callback record, not hardcoded.
        say_nick_not_found(selector, truster_nick, command: "@server gettrust %nick% #{trustee_nick}")
      }) do |target|
        truster = target
      end
      
      Player.best_match_by_nick(trustee_nick, no_match: -> {
        # FIXME The 'command' option should come from the callback record, not hardcoded.
        say_nick_not_found(selector, trustee_nick, command: "@server gettrust #{truster_nick} %nick%")
      }) do |target|
        trustee = target
      end
      
      if truster == trustee
        execute <<-DONE
          tellraw #{selector} [{"color": "green", "text": "There is infinite trust for #{trustee.nick} by #{truster.nick}."}]
        DONE
      else
        level1 = trustee.reputation_sum(level: 'I', truster: truster)
        level2 = trustee.reputation_sum(level: 'II', truster: truster)
        
        if level1 != 0 || level2 != 0
          if level1 != 0
            execute <<-DONE
              tellraw #{selector} [{"color": "dark_purple", "text": "Level I Trust", "hoverEvent": {"action": "show_text", "value":"This is the sum of direct trust for #{trustee.nick} by #{truster.nick}."}}, {"color": "green", "text": " for #{trustee.nick} by #{truster.nick}: "}, {"color": "blue", "text": "#{level1}"}]
            DONE
          end
          
          if level2 != 0
            execute <<-DONE
              tellraw #{selector} [{"color": "dark_purple", "text": "Level II Trust", "hoverEvent": {"action": "show_text", "value":"This is the sum of all trust for #{trustee.nick} by those #{truster.nick} trusts."}}, {"color": "green", "text": " for #{trustee.nick} via #{truster.nick}: "}, {"color": "blue", "text": "#{level2}"}]
            DONE
          end
        elsif !trustee.registered?
          execute <<-DONE
            tellraw #{selector} [{"color": "green", "text": "#{trustee.nick} cannot be trusted."}]
          DONE
        elsif !truster.registered?
          execute <<-DONE
            tellraw #{selector} [{"color": "green", "text": "#{truster.nick} cannot trust."}]
          DONE
        else
          execute <<-DONE
            tellraw #{selector} [{"color": "green", "text": "No trust exists for #{trustee.nick} by #{truster.nick}."}]
          DONE
        end
      end
    end
    
    def say_gametick(selector)
      latest_gametick = Preference.latest_gametick
      latest_gametick_population = Preference.latest_gametick_population.to_i
      latest_gametick_timestamp = Preference.latest_gametick_timestamp
      latest_gametick_at = Time.at(latest_gametick_timestamp.to_i) unless latest_gametick_timestamp.nil?
      ago = distance_of_time_in_words_to_now(latest_gametick_at) unless latest_gametick_at.nil?
      
      if Preference.latest_gametick_in_progress?
        say(selector, "Still checking ...")
        if latest_gametick_at > 10.seconds.ago
          execute('debug stop')
          Preference.latest_gametick_in_progress = false
        end
      elsif latest_gametick_timestamp.nil? || (latest_gametick_at < 10.minutes.ago)
        say(selector, "Checking ...")
        begin
          Preference.latest_gametick_timestamp = Time.now.to_i
          Preference.latest_gametick_in_progress = true
          execute('debug start')
          sleep 10
        rescue Exception => e
          Rails.logger.error "Failed to get gametick: #{e.inspect}"
        ensure
          execute('debug stop')
          Preference.latest_gametick_in_progress = false
        end
        
        if !!(report = Server.latest_debug_report)
          gametick = report.split("\n")[5].split(" ")[4]
          gametick_population = Server.player_nicks.size
          
          if latest_gametick_at.nil?
            say(selector, "Latest gametick: #{gametick} with #{pluralize(gametick_population, 'player')}; ideal gametick: 20.0")
          else
            say(selector, "Gametick from #{ago} ago was: #{latest_gametick} with #{pluralize(latest_gametick_population, 'player')}; latest: #{gametick} with #{pluralize(gametick_population, 'player')}; ideal gametick: 20.0")
          end
          
          Preference.latest_gametick = gametick
          Preference.latest_gametick_population = gametick_population
        end
      else
        say(selector, "Gametick from #{ago} ago was: #{latest_gametick} with #{pluralize(latest_gametick_population, 'player')}; ideal gametick: 20.0")
      end
      
      gametick || Preference.latest_gametick
    end  
  end
end
