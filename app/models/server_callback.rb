class ServerCallback < ActiveRecord::Base
  ALL_MATCH_SCHEMES = %w(any player_chat player_emote player_chat_or_emote server_message)
  
  validates :name, presence: true
  validates_uniqueness_of :name, case_sensitive: true
  validates :pattern, presence: true
  validates :command, presence: true
  validate :valid_pattern, if: :pattern_changed?
  validate :valid_command, if: :command_changed?

  after_validation :remove_pretty_pattern, if: :pattern_changed?
  after_validation :remove_pretty_command, if: :command_changed?

  scope :system, lambda { |system = true| where(system: system) }
  scope :match_scheme, lambda { |match_scheme = ALL_MATCH_SCHEMES| where(match_scheme: match_scheme) }
  scope :match_any, -> { match_scheme('any') }
  scope :match_player_chat, -> { match_scheme('player_chat') }
  scope :match_player_emote, -> { match_scheme('player_emote') }
  scope :match_player_chat_or_emote, -> { match_scheme('player_chat_or_emote') }
  scope :match_server_message, -> { where(match_scheme: 'server_message') }
  scope :enabled, lambda { |enabled = true| where(enabled: enabled) }
  scope :ready, lambda { |ready = true|
    if ready
      enabled.where('server_callbacks.ran_at IS NULL OR datetime(server_callbacks.ran_at, server_callbacks.cooldown) <= ?', Time.now)
    else
      enabled.where('server_callbacks.ran_at IS NOT NULL AND datetime(server_callbacks.ran_at, server_callbacks.cooldown) > ?', Time.now)
    end
  }
  scope :error_flagged, lambda { |error_flagged = true|
    if error_flagged
      where('server_callbacks.error_flag_at IS NOT NULL')
    else
      where('server_callbacks.error_flag_at IS NULL')
    end
  }
  scope :dirty, -> { where("server_callbacks.last_match IS NOT NULL OR server_callbacks.last_command_output IS NOT NULL OR server_callbacks.ran_at IS NOT NULL") }
  scope :needs_prettification, lambda { |needs_prettification = true|
    if needs_prettification
      where('server_callbacks.pretty_pattern IS NULL OR server_callbacks.pretty_command IS NULL')
    else
      where('server_callbacks.pretty_pattern IS NOT NULL AND server_callbacks.pretty_command IS NOT NULL')
    end
  }
  scope :query, lambda { |query|
    clause = <<-DONE
      server_callbacks.name LIKE ? OR
      server_callbacks.pattern LIKE ? OR
      server_callbacks.last_match LIKE ? OR
      server_callbacks.last_command_output LIKE ? OR
      server_callbacks.command LIKE ?
    DONE
    where(clause, query, query, query, query, query)
  }

  def to_param
    "#{id}-#{name.parameterize}"
  end
  
  def valid_pattern
    eval_check(:pattern)
  end

  def valid_command
    eval_check(:command)
    
    unless ['player_chat', 'player_emote', 'player_chat_or_emote'].include? match_scheme
      if command =~ /%nick%/
        errors[:command] << "cannot reference %nick% in a #{match_scheme.titleize} callback.  Try %1% if you intend to capture the nick yourself."
      end
    end
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
    return true unless ran?
    
    ServerCallback.where(id: self).ready.any?
  end
  
  def ran!
    self.ran_at = Time.now
    save
  end

  def ran?
    ran_at.present?
  end

  def error_flag!
    self.error_flag_at = Time.now
    save
  end

  def error_flag?
    error_flag_at.present?
  end

  def remove_pretty_pattern
    self.pretty_pattern = nil
  end

  def remove_pretty_command
    self.pretty_command = nil
  end
  
  def prettify key
    code = send(key)
    uri = URI.parse('http://pygments.appspot.com/')
    request = Net::HTTP.post_form(uri, {lang: 'ruby', code: code})
    update_attribute("pretty_#{key.to_s}".to_sym, request.body)
  end
end
