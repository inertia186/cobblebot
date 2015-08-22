module Relayable
  extend Commandable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def irc_say_event(selector, message)
      return if selector.nil?
    
      Rails.logger.info "From IRC: #{message}"
    
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
            { "color": "white", "text":"] #{message}" }
          ]
        DONE
      else
        execute <<-DONE
          tellraw @a [
            { "color": "white", "text": "[" },
            { "color": "gold", "text": "irc" },
            { "color": "white", "text": "] #{message}" }
          ]
        DONE
      end
    end
    
    def irc_say(selector, irc_nick, message)
      return if selector.nil?
    
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
    
    def irc_reply(nick, message)
      return unless Preference.irc_enabled?

      player = Player.find_by_nick(nick)
    
      if Preference.active_in_irc.to_i > 0
        Message::IrcReply.create(body: "<#{nick}> #{message}", author: player)
      end
    end

    def irc_event(message)
      return unless Preference.irc_enabled?
    
      if Preference.active_in_irc.to_i > 0
        Message::IrcReply.create(body: message)
      end
    end
  end
end