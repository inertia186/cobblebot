module Detectable
  extend Commandable
  
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
  end
end
