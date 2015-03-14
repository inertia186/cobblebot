class ServerCallback < ActiveRecord::Base
  ALL_MATCH_SCHEMES = %w(any player_chat player_emote player_chat_or_emote server_message)
  
  validates :name, presence: true
  validates_uniqueness_of :name, case_sensitive: true
  validates :pattern, presence: true
  validates :command, presence: true

  scope :match_any, -> { where(match_scheme: 'any') }
  scope :match_player_chat, -> { where(match_scheme: 'player_chat') }
  scope :match_player_emote, -> { where(match_scheme: 'player_emote') }
  scope :match_player_chat_or_emote, -> { where(match_scheme: 'player_chat_or_emote') }
  scope :match_server_message, -> { where(match_scheme: 'server_message') }
  scope :enabled, -> { where.not(enabled: [false, 'f']) } #lambda { |enabled = true| where(enabled: enabled) }
  scope :ready, -> { enabled.where('server_callbacks.ran_at IS NULL OR datetime(server_callbacks.ran_at, server_callbacks.cooldown) <= ?', Time.now) }

  def to_param
    "#{id}-#{name.parameterize}"
  end
  
  def ready?
    return true unless ran_at
    
    ServerCallback.ready.include?(self)
  end
  
  def ran!
    self.ran_at = Time.now
    save
  end
end
