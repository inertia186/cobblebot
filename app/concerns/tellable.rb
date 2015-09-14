module Tellable
  extend Commandable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    ## Simuates /tell
    def tell(selector, message, options = {as: 'Server'})
      return if selector.nil?
    
      execute <<-DONE
        tellraw #{selector} { "color": "gray", "text":"#{options[:as]} whispers to you: #{message}" }
      DONE
    end

    def tell_motd(selector)
      return unless !!Preference.motd
      results = []
    
      return if selector.nil?
    
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
  
    def add_tip(nick, tip, options = {})
      return tell(nick, 'Tip not added.  Nice try.') if tip =~ /@@/
      return tell(nick, 'Tip not added.  Entity selector no longer supported.') if tip =~ /@e/
      return tell(nick, 'Tip not added.  Sheez, do you know how annoying that selector would be?') if tip =~ /@a/
      return tell(nick, 'Tip not added.  Similar tip exists.') if Message::Tip.where("lower(messages.body) LIKE ?", "%#{tip.downcase}%").any?
    
      reply = options[:reply]
    
      # Try to get keywords if the tip contains a link.
      result = say_link(nil, tip)
      
      author = Player.any_nick(nick).first
      keywords = result[1] if result.class == Array
      keywords = result.title if result.class == Link
      _tip = Message::Tip.new(body: tip, author: author, keywords: keywords)
    
      if _tip.save
        tell(nick, 'Tip added, thank you.')
        latest_tip = Message::Tip.order(:read_at).last
        latest_tip.replies << _tip if !!reply && !!latest_tip
      else
        tell(nick, "Tip not added.")
      end
    end

    def tell_mail(nick, sub_command = nil)
      player = Player.find_by_nick nick
      return if player.nil?

      sub_command, args = sub_command.to_s.strip.downcase.split(' ')
      
      if sub_command.present?
        case sub_command
        when 'clear'
          count = player.messages.deleted(false).muted(false).update_all(deleted_at: Time.now)
          tell(nick, "#{pluralize(count, 'message')} cleared.")
        when 'mute'
          if args.nil?
            nicks = player.muted_players.map(&:nick)
            nicks = if nicks.any?
              nicks.to_sentence
            else
              'none'
            end
            return tell(nick, "Here is the list of players you have muted: #{nicks}")
          elsif args == '@a'
            Server.players.map(&:nick).each do |to_mute_nick|
              tell_mail(nick, "mute #{to_mute_nick}")
            end
            
            return
          elsif args == '@r' || args == '@p'
            args = Server.player_nicks(args).first
          elsif args == '@e'
            return tell(nick, "Spy Chicken has been muted.")
          end
          
          Player.best_match_by_nick(args, no_match: -> {
            # FIXME The 'command' option should come from the callback record, not hardcoded.
            say_nick_not_found(nick, args, command: "@server mail mute %nick%")
          }) do |to_mute|
            return tell(nick, "#{to_mute.nick} has already been muted.") if player.muted_players.include?(to_mute)
          
            mute = player.mutes.build(muted_player: to_mute)
            if mute.save
              tell(nick, "#{to_mute.nick} has been muted.")
            else
              tell(nick, "#{to_mute.nick} has not been muted: #{mute.errors.messages.first.last[0]}")
            end
          end
        when 'unmute'
          if args.nil?
            nicks = player.muted_players.map(&:nick)
            nicks = if nicks.any?
              nicks.to_sentence
            else
              'none'
            end
            return tell(nick, "Here is the list of players you have muted: #{nicks}")
          elsif args == '@r' || args == '@p'
            args = Server.player_nicks(args).first
          elsif args == '@a'
            count = player.mutes.where(muted_player_id: Server.players).destroy_all.size
            return tell(nick, "Unmuted #{pluralize(count, 'player')}.")
          elsif args == '@e'
            return tell(nick, "Spy Chicken has been unmuted.")
          end
          
          Player.best_match_by_nick(args, no_match: -> {
            # FIXME The 'command' option should come from the callback record, not hardcoded.
            say_nick_not_found(nick, args, command: "@server mail unmute %nick%")
          }) do |to_unmute|
            mute = player.mutes.find_by_muted_player_id to_unmute
          
            if mute.nil?
              tell(nick, "#{to_unmute.nick} has not been unmuted because they were not first muted.")
            elsif !mute.destroy.persisted?
              tell(nick, "#{to_unmute.nick} has been unmuted.")
            else
              tell(nick, "#{to_unmute.nick} has not been unmuted: #{mute.errors.messages.first.last}")
            end
          end
        else
          say_help(nick, 'mail')
        end
        
        return
      end

      if (mail = player.messages.deleted(false).muted(false)).any?
        mail.each do |message|
          author_nick = message.author.nick rescue '???'
          body = escape(message.body)
          color = if message.read_at.nil?
            'gray'
          else
            'dark_gray'
          end
          
          execute <<-DONE
            tellraw #{nick} [
              {
                "color": "#{color}", "text": "#{distance_of_time_in_words_to_now(message.created_at)} ago: ",
                "hoverEvent": {
                  "action": "show_text", "value": "#{message.created_at.to_s}"
                }
              },
              { "color": "#{color}", "text": "<" }, {
                "color": "dark_purple", "underlined": "true", "text": "#{author_nick}",
                "clickEvent": {
                  "action": "suggest_command", "value": "@#{author_nick} "
                }
              }, { "color": "#{color}", "text": "> #{body}" }
            ]
          DONE
          say_link(nick, body, nick: author_nick) if body =~ /^http.*/i
        
          message.touch(:read_at) # no AR callbacks
        end
      else
        tell(nick, "No mail. ;(")        
      end
    end
    
    def tell_topic(selector)
      results = []
      
      if (topic = Message::Topic.last).nil?
        results << execute(
        <<-DONE
          tellraw #{selector} { "text": "There is no topic.", "color": "green" }
        DONE
        )

        return results
      end
      
      author_nick = topic.author.nick rescue '???'
      body = escape(topic.body)
      
      results << execute(
      <<-DONE
        tellraw #{selector} { "text": "Current Topic", "color": "green" }
      DONE
      )
      results << execute(
      <<-DONE
        tellraw #{selector} { "text": "===", "color": "green" }
      DONE
      )
      results << execute(
      <<-DONE
        tellraw #{selector} { "text": "#{body}", "color": "green" }
      DONE
      )
      
      say_link(selector, body, nick: author_nick) if body =~ /^http.*/i
    end
    
    def set_topic(nick, topic)
      return tell(nick, 'Topic not set.  Nice try.') if topic =~ /@@/
      return tell(nick, 'Topic not set.  Entity selector no longer supported.') if topic =~ /@e/
      return tell(nick, 'Topic not set.  Sheez, do you know how annoying that selector would be?') if topic =~ /@a/
    
      # Try to get keywords if the topic contains a link.
      result = say_link(nil, topic)
      
      author = Player.any_nick(nick).first
      keywords = result[1] if result.class == Array
      keywords = result.title if result.class == Link
      _topic = Message::Topic.new(body: topic, author: author, keywords: keywords)
    
      if _topic.save
        tell(nick, 'Topic set, thank you.')
      else
        tell(nick, "Topic not set.")
      end
    end
    
    def tell_donations(selector)
      say_json_preference(selector, :donations_json)
      
      results = []
      
      unless (donations = Message::Donation.order(:created_at)).any?
        results << execute(
        <<-DONE
          tellraw #{selector} { "text": "No donations have been received.", "color": "green" }
        DONE
        )

        return results
      end

      donations.each do |donation|
        author_nick = donation.author.nick rescue '???'
        body = escape(donation.body)
      
        results << execute(
        <<-DONE
          tellraw #{selector} { "text": "#{body}", "color": "green" }
        DONE
        )
      
        say_link(selector, body, nick: author_nick) if body =~ /^http.*/i
      end
      
      results
    end
  end
end
