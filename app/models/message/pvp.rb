class Message::Pvp < Message
  after_initialize :setup_defaults

  def self.record(options = {})
    body = options[:body]
    created_at = options[:created_at]
    
    return if body.nil? || created_at.nil?
    
    words = body.split(' ')
    loser = nil
    winner = nil
    
    words.each do |word|
      if loser.nil?
        loser = Player.any_nick(word).first
        next unless loser.nil?
      end
      
      if winner.nil?
        winner = Player.any_nick(word).first
        break unless winner.nil?
      end
    end
    
    if !!loser && !!winner
      loser.pvp_losses.create(body: body, author: winner, created_at: created_at)
    end
  end
  
  def setup_defaults
    self.recipient_term ||= '@a'
  end
end
