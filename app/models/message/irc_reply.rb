class Message::IrcReply < Message
  after_initialize :setup_defaults
  after_create { Message::IrcReply.cull }
  
  def self.cull
    retained = order(created_at: :desc, id: :desc).limit(10).select(:id)
    where.not(id: retained).destroy_all
  end
  
  def setup_defaults
    self.recipient_term ||= '@a'
  end
end
