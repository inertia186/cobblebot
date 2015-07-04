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

    def tell_mail(nick)
      player = Player.find_by_nick nick
      return if player.nil?

      if (mail = player.messages.unread_or_read_since(2.months.ago)).any?
        mail.each do |message|
          body = message.body
          execute <<-DONE
            tellraw #{nick} [
              {
                "color": "gray", "text": "#{distance_of_time_in_words_to_now(message.created_at)} ago: ",
                "hoverEvent": {
                  "action": "show_text", "value": "#{message.created_at.to_s}"
                }
              },
              { "color": "gray", "text": "<#{message.author.nick rescue '???'}> #{body}" }
            ]
          DONE
          say_link(nick, body) if body =~ /^http.*/i
        
          message.touch(:read_at) # no AR callbacks
        end
      else
        tell(nick, "No mail.")        
      end
    end
  end
end
