module Emotable
  extend Commandable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    ## Simuates /me
    def emote(selector, message, options = {color: 'white', as: 'Server'})
      return if selector.nil?
    
      execute <<-DONE
        tellraw #{selector} [{ "color": "white", "text": "* #{options[:as]} "}, { "color": "#{options[:color]}", "text": "#{message}" }]
      DONE
    end
    
    def emote_player_prediction(selector, nick)
      player = Player.find_by_nick(nick)
      
      # Don't do prediction if the player is already logged in.
      return if Server.players.include?(player)
      
      # Don't do prediction if the player has logged in today.
      return if !!player && !!player.last_login_at && player.last_login_at > 24.hours.ago

      # Don't do prediction half the time, so it's spooky.
      return if Random.rand(10) % 2 == 0
      
      play_sound(selector, 'cf_deeper')
      emote(selector, "summons #{nick}")
    end
  end
end
