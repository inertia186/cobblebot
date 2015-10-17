class Message::Quote < Message
  after_initialize :setup_defaults

  validates_uniqueness_of :body, scope: :author, case_sensitive: false
  
  def setup_defaults
    self.recipient_term ||= '@a'
  end
end
