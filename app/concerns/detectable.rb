module Detectable
  extend Commandable

  PROJECTILES = %w(Arrow Fireball SmallFireball WitherSkull ThrownExpBottle ThrownPotion Snowball)
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def detect_spam(nick, message)
      # Don't bother to check for spam if there's only one player on.
      return if ServerQuery.numplayers.to_i < 2
    
      server_log = "#{ServerProperties.path_to_server}/logs/latest.log"
      lines = IO.readlines(server_log)
      lines = lines[([-(lines.size - 1), -50].max)..-1]
      return if lines.nil?
    
      player = Player.find_by_nick(nick)
      col = if player.nil? || player.new?
        7
      else
        20
      end
    
      regexp = player_input_regexp(nick, message)
      all = []

      lines.each do |line|
        sample = line.split(' ')[4..-1].join(' ').downcase
        all << sample[0..[sample.size - 1, col].min] if regexp.match(line)
      end

      return "No spam detected for #{nick}." if all.size == 0
    
      ratio = all.uniq.size.to_f / all.size.to_f
      handle_spam(nick, ratio)

      if !!player
        player.update_attribute(:spam_ratio, ratio) # no AR callbacks
      
        return player
      end
    end
    
    def detect_frozen_projectiles
      entities = []
      
      PROJECTILES.each do |type|
        entities += Server.entity_data(selector: "@e[type=#{type}]")
      end
      
      return entities unless entities.any?

      entities2 = []
      
      PROJECTILES.each do |type|
        entities2 += Server.entity_data(selector: "@e[type=#{type}]")
      end
      
      if entities.size == entities2.size
        # Second scan has the same result so projectiles might be stuck.
        
        Thread.start do
          handle_frozen_projectiles
        end
      end
      
      entities2
    end
  private
    def player_input_regexp(nick, message)
      chat_regex = %r(: \<#{nick}\> .*#{message[0..[message.size - 1, 7].min]}.*)i
      emote_regex = %r(: \* #{nick} .*#{message[0..[message.size - 1, 7].min]}.*)i
      Regexp.union([chat_regex, emote_regex])
    end
    
    def handle_spam(nick, ratio)
      if ratio <= 0.2 && ratio > 0.126
        say(nick, 'Warning, spam detected.', color: 'yellow', as: 'Server')
      elsif ratio <= 0.126 && ratio > 0.1
        say(nick, 'Warning, spam detected.', color: 'red', as: 'Server')
        play_sound(nick, 'oot_navi_listen')
      elsif ratio <= 0.1
        @kicked_for_spam ||= []

        if @kicked_for_spam.include? nick
          player = Player.find_by_nick(nick)
          
          player.ban!('annoying chat', announce: true) and return if !!player && player.new?
        end
        
        kick(nick, "Spammy ratio #{ratio}")
        @kicked_for_spam << nick
      end
    end
    
    def handle_frozen_projectiles
      execute 'scoreboard objectives add isJunk dummy'
      
      PROJECTILES.each do |type|
        execute "scoreboard players add @e[type=#{type}] isJunk 1"
      end

      sleep 5 # Give non-frozen projectiles time to land.

      PROJECTILES.each do |type|
        execute "kill @e[type=#{type},score_isJunk_min=1]"
      end
      
      execute 'scoreboard objectives remove isJunk' # We don't want the scoreboard to grow and grow.
    end
  end
end
