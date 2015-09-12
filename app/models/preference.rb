class Preference < ActiveRecord::Base
  WEB_ADMIN_PASSWORD = 'web_admin_password'
  PATH_TO_SERVER = 'path_to_server'
  COMMAND_SCHEME = 'command_scheme'
  MOTD = 'motd'
  RULES_JSON = 'rules_json'
  TUTORIAL_JSON = 'tutorial_json'
  FAQ_JSON = 'faq_json'
  DONATIONS_JSON = 'donations_json'
  IRC_ENABLED = 'irc_enabled'
  IRC_INFO = 'irc_info'
  IRC_WEB_CHAT_ENABLED = 'irc_web_chat_enabled'
  IRC_WEB_CHAT_URL_LABEL = 'irc_web_chat_url_label'
  IRC_WEB_CHAT_URL = 'irc_web_chat_url'
  IRC_SERVER_HOST = 'irc_server_host'
  IRC_SERVER_PORT = 'irc_server_port'
  IRC_NICK = 'irc_nick'
  IRC_CHANNEL = 'irc_channel'
  IRC_CHANNEL_OPS = 'irc_channel_ops'
  IRC_NICKSERV_PASSWORD = 'irc_nickserv_password'
  ORIGIN_SALT = 'origin_salt'
  DB_IP_API_KEY = 'db_ip_api_key'
  MMP_API_KEY = 'mmp_api_key'

  # System keys are used internally, typically hidden from the web views.
  LATEST_RESOURCE_PACK_HASH = 'latest_resource_pack_hash'
  LATEST_RESOURCE_PACK_TIMESTAMP = 'latest_resource_pack_timestamp'
  IS_JUNK_OBJECTIVE_TIMESTAMP = 'is_junk_objective_timestamp'
  ACTIVE_IN_IRC = 'active_in_irc'
  LATEST_GAMETICK = 'latest_gametick'
  LATEST_GAMETICK_POPULATION = 'latest_gametick_population'
  LATEST_GAMETICK_TIMESTAMP = 'latest_gametick_timestamp'
  LATEST_GAMETICK_IN_PROGRESS = 'latest_gametick_in_progress'

  ALL_KEYS = [
    WEB_ADMIN_PASSWORD, PATH_TO_SERVER, COMMAND_SCHEME, MOTD, RULES_JSON,
    TUTORIAL_JSON, FAQ_JSON, DONATIONS_JSON, LATEST_RESOURCE_PACK_HASH,
    LATEST_RESOURCE_PACK_TIMESTAMP, IRC_ENABLED, IRC_INFO, IRC_WEB_CHAT_ENABLED,
    IRC_WEB_CHAT_URL_LABEL, IRC_WEB_CHAT_URL, IRC_SERVER_HOST, IRC_SERVER_PORT,
    IRC_NICK, IRC_CHANNEL, IRC_CHANNEL_OPS, IRC_NICKSERV_PASSWORD, ORIGIN_SALT,
    DB_IP_API_KEY, MMP_API_KEY, IS_JUNK_OBJECTIVE_TIMESTAMP, ACTIVE_IN_IRC,
    LATEST_GAMETICK, LATEST_GAMETICK_POPULATION, LATEST_GAMETICK_TIMESTAMP,
    LATEST_GAMETICK_IN_PROGRESS
  ]

  SYSTEM_KEYS = [
    LATEST_RESOURCE_PACK_HASH, LATEST_RESOURCE_PACK_TIMESTAMP,
    IS_JUNK_OBJECTIVE_TIMESTAMP, ACTIVE_IN_IRC, LATEST_GAMETICK,
    LATEST_GAMETICK_POPULATION, LATEST_GAMETICK_TIMESTAMP,
    LATEST_GAMETICK_IN_PROGRESS
  ]

  scope :system, lambda { |system = true| where(system: system) }

  validates_uniqueness_of :key

  after_initialize :init_defaults

  def self.method_missing(m, *args, &block)
    n = m.to_s
    
    return update! prefix(n, '='), args[0] if prefixed? n, '='
    return truthy? prefix(n, '?') if prefixed? n, '?'
    return find_or_create_by!(key: n).value if has? n
      
    super
  end
  
  def init_defaults
    return unless new_record?
    
    self.system = SYSTEM_KEYS.include?(key)
  end
  
  def to_param
    key.parameterize
  end
  
  def self.find_or_create_all(system = true)
    result = []
    keys = ALL_KEYS
    keys -= SYSTEM_KEYS unless system
    
    keys.each do |key|
      result << Preference.find_or_create_by(key: key)
    end
    
    result
  end
private
  def self.prefixed?(method, op)
    method.ends_with?(op) && has?(prefix(method, op))
  end

  def self.prefix(method, op)
    method.split(op)[0]
  end

  def self.update!(key, value)
    find_or_create_by!(key: key).update_attribute(:value, value) # no AR callbacks
  end

  def self.truthy?(key)
    ['true', true, 't', '1'].include? find_or_create_by!(key: key).value
  end
  
  def self.has?(key)
    ALL_KEYS.include? key
  end
end
