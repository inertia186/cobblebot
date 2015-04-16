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
      players = Player.any_nick(nick).order(:nick)
      return say_nick_not_found(selector, nick) unless !!(player = players.first)

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
    
    def say_nick_not_found(selector, nick)
      results = [line_1 = "Player not found: #{nick}"]
      say(selector, line_1)
      players = Player.search_any_nick(nick)
      if players.any?
        results << line_2 = "Did you mean: #{players.first.nick}"
        say(selector, line_2)
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
      @no_tips ||= 0
      keywords = keywords.split(' ').map(&:strip)
      tip_body = nil
    
      tip = Message::Tip.query(keywords).in_cooldown(false).first(10).sample
    
      if !!tip
        tip_body = sub_safe_selectors(escape(tip.body.dup))
        tip.update_attribute(:read_at, Time.now) # set cooldown
        if tip_body =~ /^server/i
          emote(selector, tip_body.split(' ')[1..-1].join(' '))
        elsif tip_body =~ /^herobrine/i
          say_fake_achievement(selector, 'Herobrine', tip_body)
        elsif tip_body =~ /^slap/i
          say_slap(selector, tip_body.split(' ')[1..-1].join(' '))
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
    
      tip_body
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
  end
end
