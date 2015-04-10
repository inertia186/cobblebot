module Detectable
  extend ActiveSupport::Concern
  extend Commandable
  
  module ClassMethods
    def detect_spam(nick, message)
      # Don't bother to check for spam if there's only one player on.
      return if Server.player_nicks.size < 2
    
      server_log = "#{ServerProperties.path_to_server}/logs/latest.log"
      lines = IO.readlines(server_log)
      lines = lines[([-(lines.size - 1), -50].max)..-1]
      return if lines.nil?
    
      chat_regex = %r(: \<#{nick}\> .*#{message[0..[message.size - 1, 7].min]}.*)i
      emote_regex = %r(: \* #{nick} .*#{message[0..[message.size - 1, 7].min]}.*)i
      all = []

      lines.each do |line|
        sample = line.split(' ')[4..-1].join(' ')
        all << sample[0..[sample.size - 1, 7].min] if line =~ chat_regex || line =~ emote_regex
      end

      return "No spam detected for #{nick}." if all.size == 0
    
      ratio = all.uniq.size.to_f / all.size.to_f

      if ratio <= 0.2 && ratio > 0.126
        say(nick, 'Warning, spam detected.', color: 'yellow', as: 'Server')
      elsif ratio <= 0.126 && ratio > 0.1
        say(nick, 'Warning, spam detected.', color: 'red', as: 'Server')
        play_sound(nick, 'oot_navi_listen')
      elsif ratio <= 0.1
        execute("kick #{nick} Spammy ratio #{ratio}")
      end
    
      player = Player.find_by_nick(nick)
    
      if !!player
        player.update_attribute(:spam_ratio, ratio)
      
        return player
      end
    end
  end
end
