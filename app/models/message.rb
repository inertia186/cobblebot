class Message < ActiveRecord::Base
  scope :query, lambda { |*keywords|
    keywords = [keywords].flatten.map { |k| "%#{k.to_s.downcase}%" }

    clauses = []
    keywords.size.times { clauses << "lower(messages.body) LIKE ?" }
    keywords.size.times { clauses << "lower(messages.keywords) LIKE ?" }
    select("messages.*, ( SELECT COUNT(*) WHERE lower(messages.body) LIKE '#{keywords.join('%')}' OR lower(messages.keywords) LIKE '#{keywords.join('%')}' ) as weight").
    where(clauses.join(" OR "), *keywords, *keywords).
    order('weight DESC')
  }
  
  scope :read, lambda { |read = true|
    relation = where.not(read_at: since)
    read ? relation : where.not(id: relation)
  }
  
  scope :read_since, lambda { |since|
    where("messages.read_at IS NOT NULL AND messages.read_at > ?", since)
  }

  scope :not_read_since, lambda { |since|
    where("messages.read_at IS NULL OR messages.read_at < ?", since)
  }
  
  scope :messages, -> { where(type: nil) }
  scope :latest, lambda { |latest = 10| order(:created_at).limit(latest) }

  belongs_to :recipient, polymorphic: true
  belongs_to :author, polymorphic: true
  
  after_initialize :look_up_recipient
  
  def read!
    update_attribute(:read_at, Time.now) # no AR callbacks
  end
private
  def look_up_recipient
    return unless new_record?
    return unless type.nil?
    return unless !!recipient_term
    return if !!recipient
    
    nick = recipient_term.split('@')[1]
    
    return if nick.nil? || ( players = Player.any_nick(nick) ).count != 1
    
    self.recipient = players.first
  end
end