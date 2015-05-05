include ActionView::Helpers::DateHelper
include ActionView::Helpers::TextHelper

class Player < ActiveRecord::Base
  include Commandable
  include Tellable
  include Teleportable
  
  validates :uuid, presence: true
  validates_uniqueness_of :uuid, case_sensitive: true
  validates :nick, presence: true
  validates_uniqueness_of :nick, case_sensitive: false

  scope :any_nick, lambda { |nick| where('? IN (LOWER(nick), LOWER(last_nick))', nick.downcase) }
  scope :search_any_nick, lambda { |nick|
    search_nick = "%#{nick.downcase.chars.each.map { |c| c }.join('%')}%"
    where('LOWER(nick) LIKE ? OR LOWER(last_nick) LIKE ?', search_nick, search_nick)
  }
  scope :query, lambda { |query|
    nick = "%#{query.downcase.chars.each.map { |c| c }.join('%')}%"
    query = "%#{query}%"
    where('LOWER(nick) LIKE ? OR LOWER(last_nick) LIKE ? OR LOWER(last_chat) LIKE ? OR LAST_IP LIKE ?', nick, nick, query, query)
  }
  scope :logged_in_today, -> { where('players.last_login_at > ?', Time.now.beginning_of_day).order(:last_login_at) }
  scope :mode, lambda { |mode = :ops, enabled = true|
    if enabled
      where(uuid: Server.send(mode).map { |player| player["uuid"] })
    else
      where.not(uuid: Server.send(mode).map { |player| player["uuid"] })
    end
  }
  scope :opped, lambda { |opped = true| mode(:ops, opped) }
  scope :whitelisted, lambda { |whitelisted = true| mode(:whitelist, whitelisted) }
  scope :banned, lambda { |banned = true| mode(:banned_players, banned) }
  scope :matching_last_ip, lambda { |ip, matching_last_ip = true|
    if matching_last_ip
      where(last_ip: ip)
    else
      where.not(last_ip: ip)
    end
  }
  scope :created_after, lambda { |timestamp| where(Player.arel_table[:created_at].gt(timestamp)) }
  scope :newly_created, -> { created_after(24.hours.ago) }
  scope :matching_banned_ip, lambda { |matching_banned_ip = true| matching_last_ip(Player.banned.select(:last_ip), matching_banned_ip) }
  scope :play_sounds, lambda { |play_sounds = true| where(play_sounds: play_sounds) }
  scope :registered, lambda { |registered = true|
    if registered
      where.not(registered_at: nil)
    else
      where(registered_at: nil)
    end
  }
  scope :origin, lambda { |origin| joins(:ips).where(Ip.arel_table[:origin].in(origin)) }
  scope :address, lambda { |address| joins(:ips).where(Ip.arel_table[:address].in(address)) }

  has_many :links, as: :actor
  has_many :messages, -> { where(type: nil) }, as: :recipient
  has_many :tips, class_name: 'Message::Tip', as: :author
  has_many :ips

  before_save :update_biomes_explored

  def self.max_explore_all_biome_progress
    all.map(&:explore_all_biome_progress).map(&:to_i).max
  end

  def players_with_same_ip
    Player.where(id: Ip.where(id: ips.select(:id)).where.not(player_id: id) )
  end

  def to_param
    "#{id}-#{nick.parameterize}"
  end
  
  def logged_in?
    Server.players.include? self
  end
  
  def new?
    Player.newly_created.include? self
  end
  
  def registered?
    !!registered_at
  end

  def register!
    self.registered_at ||= Time.now
    
    save
  end

  def vetted?
    !!vetted_at
  end
  
  def opped?
    Server.ops.map { |player| player["uuid"] }.include? uuid
  end

  def op!
    Player.execute("op #{nick}")
  end
  
  def deop!
    Player.execute("deop #{nick}")
  end
  
  def whitelisted?
    Server.whitelist.map { |player| player["uuid"] }.include? uuid
  end
  
  def whitelist!(yes = true)
    if yes
      Player.execute("whitelist add #{nick}")
    else
      Player.execute("whitelist remove #{nick}")
    end
  end
  
  def banned?
    Server.banned_players.map { |player| player["uuid"] }.include? uuid
  end
  
  def banned_at
    nil unless banned?
    
    Time.parse(Server.banned_players.select { |player| player["uuid"] == uuid }.first['created'])
  end
  
  def banned_reason
    nil unless banned?
    
    Server.banned_players.select { |player| player["uuid"] == uuid }.first['reason']
  end
  
  def ban!(reason = '')
    Player.execute("ban #{nick} #{reason}")
  end
  
  def pardon!
    Player.execute("pardon #{nick}")
  end
  
  def kick!(reason = 'Have A Nice Day!')
    Player.kick(nick, reason)
  end
  
  def kill!
    Player.execute("kill #{nick}")
  end

  def tp!(options = {})
    x, y, z = options[:x], options[:y], options[:z]
    x_rot, y_rot = options[:x_rot], options[:y_rot]
    target_nick = options[:nick]
    
    return Player.tp(nick, "#{x} #{y} #{z} #{x_rot} #{y_rot}") if !!x && !!y && !!z
    return Player.tp(nick, "#{target_nick}") if !!target_nick
  end

  def spawnpoint!(x, y, z)
    Player.execute("spawnpoint #{nick} #{x} #{y} #{z}")
  end
  
  def title(type, json)
    Player.execute("title #{nick} #{type} #{json}")
  end

  def tell(message)
    Player.tell(nick, message)
  end

  def tellraw(json)
    Player.execute("tellraw #{nick} #{json}")
  end
  
  def last_activity_at
    Time.at([last_login_at.to_i, last_logout_at.to_i, updated_at.to_i].max)
  end

  def stats_file_path
    raise StandardError.new("Level name is incorrect.") if ServerProperties.path_to_server.nil?
    
    @stats_file_path ||= "#{ServerProperties.path_to_server}/#{ServerProperties.level_name}/stats/#{uuid}.json"
  end
  
  def player_data
    @player_data = JSON[File.read stats_file_path] if File.exists? stats_file_path
  end
  
  def explore_all_biome_progress
    achievements.explore_all_biomes['progress'].count rescue 0
  end
  
  def time_since_death
    "%.2f hours" % (stats.time_since_death / 60.0 / 60.0 / 24.0) if player_data
  end
  
  def last_location
    response = tp!(x: '~', y: '~', z: '~')
    
    reload.last_location
  end
  
  def current_pos
    [$1.to_i, $2.to_i, $3.to_i] if current_location =~ /^x=([0-9]+),y=([0-9]+),z=([0-9]+)$/
  end

  def last_pos
    [$1.to_i, $2.to_i, $3.to_i] if last_location =~ /^x=([0-9]+),y=([0-9]+),z=([0-9]+)$/
  end
  
  def update_biomes_explored
    self.biomes_explored = explore_all_biome_progress
  end

  def toggle_play_sounds!
    update_attribute(:play_sounds, !play_sounds) # no AR callbacks
  end
  
  def method_missing(m, *args, &block)
    return super unless !!player_data
    return player_data[m.to_s] if player_data.keys.include?(m.to_s)
    return player_data_key_group(m.to_s) if player_data_key_group?(m.to_s)

    super
  end
  
  def reload
    @stats_file_path = nil
    @player_data = nil
    
    super
  end
  
  def origins
    ips.map(&:origin).uniq
  end
private  
  def player_data_key_group?(key)
    player_data.keys.map { |key| key.split('.')[0] }.include?(key.singularize)
  end
  
  def player_data_key_group(key)
    player_data.keys.reduce({}) do |hash, (k, v)|
      single_key_group?(k, key) ? single_key_group(k, hash) : hash
    end.tap { |these| return Struct.new(*these.keys).new(*these.values) }
  end
  
  def single_key_group?(k, key)
    k.split('.')[0] == key.singularize
  end
  
  def single_key_group(key, hash)
    hash.merge(key.split('.')[1].underscore.to_sym => player_data[key])
  end
end
