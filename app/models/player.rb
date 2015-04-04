include ActionView::Helpers::DateHelper
include ActionView::Helpers::TextHelper

class Player < ActiveRecord::Base
  validates :uuid, presence: true
  validates_uniqueness_of :uuid, case_sensitive: true
  validates :nick, presence: true
  validates_uniqueness_of :nick, case_sensitive: false

  scope :any_nick, lambda { |nick| where('? IN (LOWER(nick), LOWER(last_nick))', nick.downcase) }
  scope :search_any_nick, lambda { |nick|
    search_nick = "%#{nick.downcase.chars.each.map { |c| c }.join('%')}%"
    where('LOWER(nick) LIKE ? OR LOWER(last_nick) LIKE ?', search_nick, search_nick)
  }
  scope :logged_in_today, -> { where('players.last_login_at > ?', Time.now.beginning_of_day).order(:last_login_at) }
  scope :opped, lambda { |opped = true|
    if opped
      where(uuid: Server.ops.map { |player| player["uuid"] })
    else
      where.not(uuid: Server.ops.map { |player| player["uuid"] })
    end
  }
  scope :whitelisted, lambda { |whitelisted = true|
    if whitelisted
      where(uuid: Server.whitelist.map { |player| player["uuid"] })
    else
      where.not(uuid: Server.whitelist.map { |player| player["uuid"] })
    end
  }
  scope :banned, lambda { |banned = true|
    if banned
      where(uuid: Server.banned_players.map { |player| player["uuid"] })
    else
      where.not(uuid: Server.banned_players.map { |player| player["uuid"] })
    end
  }
  scope :matching_last_ip, lambda { |ip, matching_last_ip = true|
    if matching_last_ip
      where(last_ip: ip)
    else
      where.not(last_ip: ip)
    end
  }
  scope :matching_banned_ip, lambda { |matching_banned_ip = true| matching_last_ip(Player.banned.select(:last_ip), matching_banned_ip) }

  has_many :links, as: :actor
  has_many :messages, -> { where(type: nil) }, as: :recipient
  has_many :tips, class_name: 'Message::Tip', as: :author

  def self.max_explore_all_biome_progress
    all.map(&:explore_all_biome_progress).map(&:to_i).max
  end

  def to_param
    "#{id}-#{nick.parameterize}"
  end
  
  def logged_in?
    Server.players.include? self
  end
  
  def new?
    created_at.nil? || created_at > 24.hours.ago
  end
  
  def registered?
    !!registered_at
  end

  def vetted?
    !!vetted_at
  end
  
  def opped?
    Server.ops.map { |player| player["uuid"] }.include? uuid
  end

  def op!
    ServerCommand.execute("op #{nick}")
  end
  
  def deop!
    ServerCommand.execute("deop #{nick}")
  end
  
  def whitelisted?
    Server.whitelist.map { |player| player["uuid"] }.include? uuid
  end
  
  def whitelist!(yes = true)
    if yes
      ServerCommand.execute("whitelist add #{nick}")
    else
      ServerCommand.execute("whitelist remove #{nick}")
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
    ServerCommand.execute("ban #{nick} #{reason}")
  end
  
  def pardon!
    ServerCommand.execute("pardon #{nick}")
  end
  
  def kick!(reason = 'Have A Nice Day!')
    ServerCommand.execute("kick #{nick} #{reason}")
  end
  
  def kill!
    ServerCommand.execute("kill #{nick}")
  end

  def tp!(options = {})
    x = options[:x]
    y = options[:y]
    z = options[:z]
    x_rot = options[:x_rot]
    y_rot = options[:y_rot]
    target_nick = options[:nick]
    
    return ServerCommand.execute("tp #{nick} #{x} #{y} #{z} #{x_rot} #{y_rot}") if !!x && !!y && !!z
    return ServerCommand.execute("tp #{nick} #{target_nick}") if !!target
  end

  def spawnpoint!(x, y, z)
    ServerCommand.execute("spawnpoint #{nick} #{x} #{y} #{z}")
  end
  
  def title(type, json)
    ServerCommand.execute("title #{nick} #{type} #{json}")
  end

  def tell(message)
    ServerCommand.execute("tell #{nick} #{message}")
  end

  def tellraw(json)
    ServerCommand.execute("tellraw #{nick} #{json}")
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
  
  def current_location
    response = ServerCommand.execute("tp #{nick} ~ ~ ~")
    return if response == 'The entity UUID provided is in an invalid format'
    
    response.split(' ')[3..-1].join(' ').split(/[\s,]+/)
  end
  
  def method_missing(m, *args, &block)
    super unless !!player_data

    key = m.to_s
    data = player_data
    
    if data.keys.include?(key)
      return data[m]
    elsif data.keys.map { |key| key.split('.')[0] }.include?(key.singularize)
      data.keys.reduce({}) do |hash, (k, v)|
        if k.split('.')[0] == key.singularize
          hash.merge(k.split('.')[1].underscore.to_sym => data[k])
        else
          hash
        end
      end.tap { |these| return Struct.new(*these.keys).new(*these.values) }
    end

    super
  end
  
  def reload
    @stats_file_path = nil
    @player_data = nil
    
    super
  end
end
