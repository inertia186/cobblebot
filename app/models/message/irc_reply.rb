class Message::IrcReply < Message
  after_initialize :setup_defaults
  after_create { Message::IrcReply.cull }
  
  def self.cull
    where.not(id: latest.select(:id)).destroy_all
  end
  
  def setup_defaults
    self.recipient_term ||= '@a'
  end
end