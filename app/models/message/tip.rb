class Message::Tip < Message
  after_initialize :setup_defaults

  validates_uniqueness_of :body, case_sensitive: false

  scope :in_cooldown, lambda { |in_cooldown = true|
    if in_cooldown
      where("messages.read_at IS NOT NULL AND messages.read_at BETWEEN ? AND ?", 24.hours.ago, Time.now)
    else
      where("messages.read_at IS NULL OR messages.read_at NOT BETWEEN ? AND ?", 24.hours.ago, Time.now)
    end
  }
  
  def setup_defaults
    self.recipient_term ||= '@a'
  end
end