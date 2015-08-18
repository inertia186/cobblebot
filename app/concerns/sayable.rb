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
        execute <<-DONE
          tellraw #{selector} [{ "color": "white", "text": "[#{options[:as]}] "}, { "color": "#{options[:color]}", "text": "#{message}" }]
        DONE
      else
        execute <<-DONE
          tellraw #{selector} { "color": "#{options[:color]}", "text": "#{message}" }
        DONE
      end
    end
    
    def say_playercheck(selector, nick)
      Player.best_match_by_nick(nick, no_match: -> { 
        # FIXME The 'command' option should come from the callback record, not hardcoded.
        say_nick_not_found(selector, nick, command: '@server playercheck %nick%')
      }) do |player|
        line_1a = "Latest activity for #{player.nick} was "
        line_1b = distance_of_time_in_words_to_now(player.last_activity_at)
        line_1c = player.last_activity_at.to_s
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
      
        # TODO get rate:
        # say selector, "Sum of all trust: ..."
    
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
        say(selector, result = "Biomes explored: #{player.explore_all_biome_progress}")
      end
      
      [result]
    end
    
    def say_nick_not_found(selector, nick, options = {})
      results = [line_1 = "Player not found: #{nick}"]
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
    
    def say_random_tip(selector, nick, keywords = '', options =())
      keywords = keywords.split(' ').map(&:strip)
      tip = nil
      
      if keywords.size == 1 && keywords[0] =~ /\d/
        tip = Message::Tip.order(:id).limit(keywords[0].to_i).last
      elsif keywords.any?
        tip = Message::Tip.query(keywords).in_cooldown(false).first
      else
        tip = Message::Tip.query(keywords).in_cooldown(false).sample
      end
      
      if tip.nil?
        tip = Message::Tip.query(keywords).in_cooldown(false).first(10).sample
      end
      
      return say_nothing(selector) unless !!tip
  
      tip_body = sub_safe_selectors(escape(tip.body.dup))
      tip.update_attribute(:read_at, Time.now) # set cooldown, no AR callbacks
      if tip_body =~ /^server/i
        emote(selector, tip_body.split(' ')[1..-1].join(' '))
      elsif tip_body =~ /^herobrine/i
        say_fake_achievement(selector, 'Herobrine', tip_body.split(' ')[1..-1].join(' '))
      elsif tip_body =~ /^slap/i
        nick = if !!tip.author
          tip.author.nick
        else
          'Server'
        end
        say_slap(selector, nick, tip_body.split(' ')[1..-1].join(' '))
      elsif tip_body =~ /^>/i
        say(selector, tip_body, color: 'green', as: 'Server')
      elsif tip_body =~ /explode/i
        play_sound(selector, 'random.explode')
        say(selector, tip_body)
      elsif tip_body =~ /there is no place like/i
        play_sound(selector, 'loz_recorder')
        say(selector, tip_body)
      else
        say(selector, tip_body)
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
    
    def tips
      tips = Message::Tip.all
      tips_in_cooldown = Message::Tip.in_cooldown
    
      say('@a', "There are currently #{tips.count} tips.  In cooldown: #{tips_in_cooldown.count}")
    end
    
    def say_slap(selector = "@a", nick = "Server", target = nil)
      result = nil
      target = target.strip if !!target
    
      if target.present?
        emote selector, result = McSlap.slap(sub_safe_selectors(target)), color: 'white', as: nick
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
    
    def say_translation(selector, pair, term)
      pair = pair.split(':')
      if pair.size == 1
        from = 'auto'
        to = pair[0].to_sym
      else
        from = pair[0].to_sym
        to = pair[1].to_sym
      end
      translator = GoogleTranslate.new
      translation = translator.translate(from, to, term)
      
      say('@a', escape(translation[0][0][0]), as: 'Google')
    end
  end
end
