module Achievable
  extend ActiveSupport::Concern
  extend Commandable
  extend Audible
  
  module ClassMethods
    def say_fake_achievement(selector, nick, achievement, hover_text = 'AH YISS', hover_obfuscated = false)
      return if selector.nil?

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
  end
end
