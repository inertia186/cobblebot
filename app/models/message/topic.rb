class Message::Topic < Message
  after_initialize :setup_defaults
  
  scope :latest_topics, -> {
    deleted(false).order('created_at DESC')
  }
  
  def setup_defaults
    self.recipient_term ||= '@a'
  end
end
