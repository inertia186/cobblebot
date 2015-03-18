class ServerCallback < ActiveRecord::Base
  ALL_MATCH_SCHEMES = %w(any player_chat player_emote player_chat_or_emote server_message)
  
  validates :name, presence: true
  validates_uniqueness_of :name, case_sensitive: true
  validates :pattern, presence: true
  validates :command, presence: true
  validate :valid_pattern, if: :pattern_changed?
  validate :valid_command, if: :command_changed?

  scope :system, lambda { |system = true| where(system: system) }
  scope :match_any, -> { where(match_scheme: 'any') }
  scope :match_player_chat, -> { where(match_scheme: 'player_chat') }
  scope :match_player_emote, -> { where(match_scheme: 'player_emote') }
  scope :match_player_chat_or_emote, -> { where(match_scheme: 'player_chat_or_emote') }
  scope :match_server_message, -> { where(match_scheme: 'server_message') }
  scope :enabled, lambda { |enabled = true| where(enabled: enabled) }
  scope :ready, -> { enabled.where('server_callbacks.ran_at IS NULL OR datetime(server_callbacks.ran_at, server_callbacks.cooldown) <= ?', Time.now) }
  scope :dirty, -> { where("last_match IS NOT NULL OR last_command_output IS NOT NULL OR ran_at IS NOT NULL") }

  def to_param
    "#{id}-#{name.parameterize}"
  end
  
  def valid_pattern
    eval_check(:pattern)
  end

  def valid_command
    eval_check(:command)
  end

  def eval_check key
    begin
      catch(:x) { eval("throw :x; #{send(key)};") }
    rescue SyntaxError => e
      syntax_error = e
    end

    if !!syntax_error
      errors[key] << 'has syntax error(s)'
      errors[:base] << syntax_error
    end
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
