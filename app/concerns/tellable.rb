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
  
    def add_tip(nick, tip)
      return tell(nick, 'Tip not added.  Nice try.') if tip =~ /@@/
      return tell(nick, 'Tip not added.  Entity selector no longer supported.') if tip =~ /@e/
      return tell(nick, 'Tip not added.  Sheez, do you know how annoying that selector would be?') if tip =~ /@a/
      return tell(nick, 'Tip not added.  Similar tip exists.') if Message::Tip.where("lower(messages.body) LIKE ?", "%#{tip.downcase}%").any?
    
      # Try to get keywords if the tip contains a link.
      result = say_link(nil, tip)
      
      author = Player.any_nick(nick).first
      keywords = result[1] if result.class == Array
      keywords = result.title if result.class == Link
      _tip = Message::Tip.new(body: tip, author: author, keywords: keywords)
    
      if _tip.save
        tell(nick, 'Tip added, thank you.')
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
            args = Server.players.sample.nick
          elsif args == '@e'
            return tell(nick, "Spy Chicken has been muted.")
          end
          
          to_mutes = Player.nick(args) # Favor an exact match (ignoring case).
          if to_mutes.none?
            # Next, favor player who matches with a preference for the most recent activity.
            to_mutes = Player.any_nick(args).order(:updated_at)
          end
    
          # FIXME The 'command' option should come from the callback record, not hardcoded.
          return say_nick_not_found(nick, args, command: "@server mail mute %nick%") unless !!(to_mute = to_mutes.first)
          
          return tell(nick, "#{to_mute.nick} has already been muted.") if player.muted_players.include?(to_mute)
          
          mute = player.mutes.build(muted_player: to_mute)
          if mute.save
            tell(nick, "#{to_mute.nick} has been muted.")
          else
            tell(nick, "#{to_mute.nick} has not been muted: #{mute.errors.messages.first.last[0]}")
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
            args = Server.players.sample.nick
          elsif args == '@a'
            count = player.mutes.where(muted_player_id: Server.players).destroy_all.size
            return tell(nick, "Unmuted #{pluralize(count, 'player')}.")
          elsif args == '@e'
            return tell(nick, "Spy Chicken has been unmuted.")
          end
          
          to_unmutes = Player.nick(args) # Favor an exact match (ignoring case).
          if to_unmutes.none?
            # Next, favor player who matches with a preference for the most recent activity.
            to_unmutes = Player.any_nick(args).order(:updated_at)
          end
    
          # FIXME The 'command' option should come from the callback record, not hardcoded.
          return say_nick_not_found(nick, args, command: "@server mail unmute %nick%") unless !!(to_unmute = to_unmutes.first)
          
          mute = player.mutes.find_by_muted_player_id to_unmute
          
          if mute.nil?
            tell(nick, "#{to_unmute.nick} has not been unmuted because they were not first muted.")
          elsif !mute.destroy.persisted?
            tell(nick, "#{to_unmute.nick} has been unmuted.")
          else
            tell(nick, "#{to_unmute.nick} has not been unmuted: #{mute.errors.messages.first.last}")
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
          say_link(nick, body) if body =~ /^http.*/i
        
          message.touch(:read_at) # no AR callbacks
        end
      else
        tell(nick, "No mail. ;(")        
      end
    end
  end
end
