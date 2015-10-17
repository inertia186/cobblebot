class ServerCallback < ActiveRecord::Base
  ALL_TYPES = %w(ServerCallback::AnyEntry ServerCallback::PlayerChat
    ServerCallback::PlayerEmote ServerCallback::AnyPlayerEntry
    ServerCallback::ServerEntry ServerCallback::AchievementAnnouncement
    ServerCallback::DeathAnnouncement ServerCallback::RunningBehind
    ServerCallback::PlayerAuthenticated)
  PLAYER_ENTRY_TYPES = %(ServerCallback::AnyEntry ServerCallback::PlayerChat
    ServerCallback::PlayerEmote ServerCallback::AnyPlayerEntry)

  REGEX_ANY = %r{^\[\d{2}:\d{2}:\d{2}\] .*$}
  REGEX_PLAYER_CHAT = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: <[^<]+> .*$}
  REGEX_PLAYER_EMOTE = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: \* [^<]+ .*$}
  REGEX_PLAYER_CHAT_OR_EMOTE = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: [\* ]*[ ]*[<]*[^<]+[>]* .*$}
  REGEX_USER_AUTHENTICATOR = %r{^\[\d{2}:\d{2}:\d{2}\] \[User Authenticator #\d+/INFO\]: .*$}
  REGEX_ACHIEVEMENT_ANNOUNCEMENT = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread/INFO\]: .* has just earned the achievement.*$}
  REGEX_RUNNING_BEHIND = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread/WARN\]: Can't keep up! Did the system time change, or is the server overloaded? Running [0-9]+ms behind, skipping [0-9]+ tick.*$}
  REGEX_PLAYER_AUTHENTICATED = %r{^\[\d{2}:\d{2}:\d{2}\] \[User Authenticator #\d+/INFO\]: UUID of player ([a-zA-Z0-9_]+) is ([a-fA-Z0-9-]+)$}
  
  validates :name, presence: true
  validates_uniqueness_of :name, case_sensitive: true
  validates :pattern, presence: true
  validates :command, presence: true
  validate :valid_pattern, if: :pattern_changed?
  validate :valid_command, if: :command_changed?
  validates_uniqueness_of :help_doc_key, allow_nil: true, allow_blank: true

  after_validation :remove_pretty_pattern, if: :pattern_changed?
  after_validation :remove_pretty_command, if: :command_changed?

  scope :system, lambda { |system = true| where(system: system) }
  scope :type, lambda { |type = ALL_TYPES| where(type: type) }
  scope :any_entry, -> { type('ServerCallback::AnyEntry') }
  scope :player_chat, -> { type('ServerCallback::PlayerChat') }
  scope :player_emote, -> { type('ServerCallback::PlayerEmote') }
  scope :any_player_entry, -> { type('ServerCallback::AnyPlayerEntry') }
  scope :server_entry, -> { type('ServerCallback::ServerEntry') }
  scope :enabled, lambda { |enabled = true| where(enabled: enabled) }
  scope :ready, lambda { |ready = true|
    adapter_type = ActiveRecord::Base.connection.adapter_name.downcase.to_sym
    clause = case adapter_type
    when :sqlite then 'server_callbacks.ran_at IS NULL OR datetime(server_callbacks.ran_at, server_callbacks.cooldown) <= ?'
    when :postgresql then 'server_callbacks.ran_at IS NULL OR server_callbacks.ran_at + (server_callbacks.cooldown::interval) <= ?'
    else raise NotImplementedError, "Unknown adapter type '#{adapter_type}'"
    end
        
    enabled.where(clause, Time.now).tap do |r|
      return ready ? r : where.not(id: r)
    end
  }
  scope :error_flagged, lambda { |error_flagged = true|
    where('server_callbacks.error_flag_at IS NOT NULL').tap do |r|
      return error_flagged ? r : where.not(id: r)
    end
  }
  scope :dirty, -> { where("server_callbacks.last_match IS NOT NULL OR server_callbacks.last_command_output IS NOT NULL OR server_callbacks.ran_at IS NOT NULL") }
  scope :needs_prettification, lambda { |needs_prettification = true|
    where('server_callbacks.pretty_pattern IS NULL OR server_callbacks.pretty_command IS NULL').tap do |r|
      return needs_prettification ? r : where.not(id: r)
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
  scope :has_help_docs, lambda { |has_help_docs = true|
    where.not(help_doc_key: [nil, '']).tap do |r|
      return has_help_docs ? r : where.not(id: r)
    end
  }
  
  def self.for_handling(line)
    raise "Cannot handle undefine callback type for: #{line}"
  end

  def self.handle(line, options = {})
    return unless for_handling(line)
    any_result = nil

    ready.find_each do |callback|
      result = callback.handle_entry(*entry(line, options))
      any_result ||= result
    end
    
    any_result
  end

  def to_param
    "#{id}-#{name.parameterize}"
  end
  
  def display_type
    type.split('::')[1..-1].join(' ').titleize
  end
  
  def valid_pattern
    eval_check(:pattern)
  end

  def valid_command
    eval_check(:command)
    
    unless ['ServerCallback::PlayerChat', 'ServerCallback::PlayerEmote', 'ServerCallback::AnyPlayerEntry'].include? type
      if command =~ /%nick%/
        errors[:command] << "cannot reference %nick% in a #{type.titleize} callback.  Try %1% if you intend to capture the nick yourself."
      end
    end
  end

  def eval_check key
    catch(:x) { eval("throw :x; #{send(key)};", Proc.new{}.binding) }
  rescue SyntaxError => e
    errors[key] << 'has syntax error(s)'
    errors[:base] << e
  end

  def player_input?(input = nil)
    case type
    when 'ServerCallback::AnyEntry'
      # FIXME This type will trigger on any log line, if there is a match.  We
      # now need to determine if the message is from a player.
      raise NotImplementedError, 'Unable to determine if input is from player'
    else
      PLAYER_ENTRY_TYPES.include? type
    end
  end

  def ready?
    return true unless ran?
    
    if respond_to? :status
      status.nil? || status <= Time.now
    else
      ServerCallback.where(id: self).ready.any?
    end
  end
  
  def handle_entry(player, message, line, options = {})
    case message
    when ServerCommand.eval_pattern(pattern, to_param)
      execute_command(player, message, options)
      update_column(:last_match, line) # no AR callbacks
      true
    else
      nil
    end
  end
  
  def execute_command(nick, message, options = {})
    update_column(:error_flag_at, nil) unless error_flag_at.nil? # no AR callbacks
    
    if player_input?(message)
      begin
        message_escaped = message
      
        # TODO Also look for and escape: []\^$.|?*+()
        %w( [ ] \\ ^ $ . | ? * + \( \)).each do |c|
          message_escaped.gsub!(c, "\\#{c}")
        end
      
        # Find quotes to avoid breaking json.
        message_escaped.gsub!(/"/, '\"')
      
        # Find ruby escaped #{vars} in strings and just remove them.
        message_escaped.gsub!(/\#{[^}]+}/, '')

        pre_eval = nil
        eval("pre_eval = \"#{message_escaped}\"", Proc.new{}.binding)
        Rails.logger.warn "Possible problem with pre eval for messsage: \"#{message}\" became \"#{pre_eval}\"" unless message == pre_eval
        message = message_escaped
      rescue SyntaxError => e
        Rails.logger.error "Syntax error escaping message: #{e.inspect}"
      rescue StandardError => e
        Rails.logger.error "Problem escaping message: #{e.inspect}"
      end
    end
    
    cmd = command.
      gsub("%message%", "#{message}").
      gsub("%nick%", "#{nick}").
      gsub("%cobblebot_version%", COBBLEBOT_VERSION)

    message.match(ServerCommand.eval_pattern(pattern, to_param)).captures.each_with_index do |capture, index|
      cmd.gsub!("%#{index + 1}%", "#{capture}")
    end if message.match(ServerCommand.eval_pattern(pattern, to_param))

    # Remove matched vars.
    cmd.gsub!(/%[^%]*%/, '')

    begin
      result = ServerCommand.eval_command(cmd, to_param, options)
      # TODO clear the error flag
    rescue StandardError => e
      Rails.logger.error result = CobbleBotError.new(e).local_backtrace
      error_flag!
    end
    
    update_columns(ran_at: Time.now, last_command_output: result.inspect) # no AR callbacks
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
    uri = URI.parse('http://pygments-1-4.appspot.com/')
    request = Net::HTTP.post_form(uri, {lang: 'ruby', code: code})
    if request.code == '200'
      update_attribute("pretty_#{key.to_s}".to_sym, request.body) # no AR callbacks
    end
  end
end
