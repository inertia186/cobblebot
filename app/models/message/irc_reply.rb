class Message::IrcReply < Message
  after_initialize :setup_defaults
  
  def setup_defaults
    self.recipient_term ||= '@a'
  end
end