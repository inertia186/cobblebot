include ActionView::Helpers::DateHelper
include ActionView::Helpers::TextHelper

class Player < ActiveRecord::Base
  include Commandable
  include Tellable
  include Teleportable
  include Audible
  include Sayable

  LANG_EN = %w(US CA GB AU IE JM NZ)
  LANG_FR = %w(BE CA FR LU MC CH)
  LANG_PT = %w(BR PT)
  LANG_ES = %w(AR VE BO CL CO CR DO EC SV GT HN MX NI PA PY PE PR ES US UY)
  
  validates :uuid, presence: true
  validates_uniqueness_of :uuid, case_sensitive: true
  validates :nick, presence: true
  validates_uniqueness_of :nick, case_sensitive: false

  scope :nick, lambda { |nick| where('LOWER(nick) = ?', nick.downcase) }
  scope :any_nick, lambda { |nick| where('? IN (LOWER(nick), LOWER(last_nick))', nick.downcase) }
  scope :search_any_nick, lambda { |nick|
    search_nick = "%#{nick.downcase.chars.each.map { |c| c }.join('%')}%"
    where('LOWER(nick) LIKE ? OR LOWER(last_nick) LIKE ?', search_nick, search_nick)
  }
  scope :query, lambda { |query|
    nick = "%#{query.downcase.chars.each.map { |c| c }.join('%')}%"
    query = "%#{query}%"
    where('LOWER(uuid) LIKE ? OR LOWER(nick) LIKE ? OR LOWER(last_nick) LIKE ? OR LOWER(last_chat) LIKE ? OR LAST_IP LIKE ?', query, nick, nick, query, query)
  }
  scope :logged_in_today, -> { where('players.last_login_at > ?', Time.now.beginning_of_day).order(:last_login_at) }
  scope :mode, lambda { |mode = :ops, enabled = true|
    where(uuid: Server.send(mode).map { |player| player["uuid"] }).tap do |r|
      return enabled ? r : where.not(id: r)
    end
  }
  scope :opped, lambda { |opped = true| mode(:ops, opped) }
  scope :whitelisted, lambda { |whitelisted = true| mode(:whitelist, whitelisted) }
  scope :banned, lambda { |banned = true| mode(:banned_players, banned) }
  scope :matching_last_ip, lambda { |ip, matching_last_ip = true|
    where(last_ip: ip).tap do |r|
      return matching_last_ip ? r : where.not(id: r)
    end
  }
  scope :within_biomes_explored, lambda { |min, max, within = true|
    where('"players"."biomes_explored" BETWEEN (?) AND (?)', min, max).tap do |r|
      return within ? r : where.not(id: r)
    end
  }
  scope :created_after, lambda { |timestamp| where(Player.arel_table[:created_at].gt(timestamp)) }
  scope :newly_created, -> { created_after(24.hours.ago) }
  scope :above_exploration_threshold, -> {
    r = Player.newly_created.select(:biomes_explored)
    return all if r.none?
    
    target = ( r.map(&:biomes_explored).sum.to_f / r.count ) * 3
    return all if target == 0.0
    
    within_biomes_explored(0, target, false)
  }
  scope :matching_banned_ip, lambda { |matching_banned_ip = true| matching_last_ip(Player.banned.select(:last_ip), matching_banned_ip) }
  scope :play_sounds, lambda { |play_sounds = true| where(play_sounds: play_sounds) }
  scope :registered, lambda { |registered = true|
    where.not(registered_at: nil).tap do |r|
      return registered ? r : where.not(id: r)
    end
  }
  scope :origin, lambda { |origin| joins(:ips).where(Ip.arel_table[:origin].in(origin)) }
  scope :address, lambda { |address| joins(:ips).where(Ip.arel_table[:address].in(address)) }
  scope :may_autolink, lambda { |may_autolink = true| where(may_autolink: may_autolink) }
  scope :spammers, lambda { |spammers = true, ratio = 0.1|
    spam_ratio = Player.arel_table[:spam_ratio]

    where(spam_ratio.lt(ratio)).tap do |r|
      return spammers ? r : where.not(id: r)
    end
  }
  scope :cc, lambda { |cc, inclusive = true|
    where(id: Ip.where(cc: cc).select(:player_id)).tap do |r|
      return inclusive ? r : where.not(id: r)
    end
  }
  scope :lang_en, lambda { |lang_en = true|
    cc(LANG_EN).tap do |r|
      return lang_en ? r : where.not(id: r).where.not(id: cc(['**', '??']))
    end
  }
  scope :lang_fr, lambda { |lang_fr = true|
    cc(LANG_FR).tap do |r|
      return lang_fr ? r : where.not(id: r).where.not(id: cc(['**', '??']))
    end
  }
  scope :lang_pt, lambda { |lang_pt = true|
    cc(LANG_PT).tap do |r|
      return lang_pt ? r : where.not(id: r).where.not(id: cc(['**', '??']))
    end
  }
  scope :lang_es, lambda { |lang_es = true|
    cc(LANG_ES).tap do |r|
      return lang_es ? r : where.not(id: r).where.not(id: cc(['**', '??']))
    end
  }
  scope :has_links, lambda { |has_links = true|
    joins(:links).uniq.tap do |r|
      return has_links ? r : where.not(id: r)
    end
  }
  scope :has_messages, lambda { |has_messages = true|
    joins(:messages).uniq.tap do |r|
      return has_messages ? r : where.not(id: r)
    end
  }
  scope :has_sent_messages, lambda { |has_sent_messages = true|
    joins(:sent_messages).uniq.tap do |r|
      return has_sent_messages ? r : where.not(id: r)
    end
  }
  scope :has_tips, lambda { |has_tips = true|
    joins(:tips).uniq.tap do |r|
      return has_tips ? r : where.not(id: r)
    end
  }
  scope :has_topics, lambda { |has_topics = true|
    joins(:topics).uniq.tap do |r|
      return has_topics ? r : where.not(id: r)
    end
  }
  scope :has_ips, lambda { |has_ips = true|
    joins(:ips).uniq.tap do |r|
      return has_ips ? r : where.not(id: r)
    end
  }

  has_many :links, as: :actor
  has_many :messages, -> { where(type: nil) }, as: :recipient
  has_many :sent_messages, -> { where(type: nil) }, class_name: 'Message', as: :author
  has_many :tips, class_name: 'Message::Tip', as: :author
  has_many :topics, class_name: 'Message::Topic', as: :author
  has_many :ips
  has_many :mutes
  has_many :inverse_mutes, foreign_key: 'muted_player_id', class_name: 'Mute'
  has_many :muted_players, through: :mutes

  before_save :update_biomes_explored
  before_save :update_last_nick, if: :nick_changed?

  def self.max_explore_all_biome_progress
    all.map(&:explore_all_biome_progress).map(&:to_i).max
  end

  def players_with_same_ip(options = {})
    a = options[:except_address] || []
    o = options[:except_origin] || []
    
    other_ips = Ip.where(address: ips.where.not(address: a, origin: o).
      select(:address)).
      where.not(player_id: id)
      
    Player.where(id: other_ips.distinct(:player_id).select(:player_id))
  end

  def self.best_match_by_nick(nick, options = {}, &block)
    # Favor an exact match (ignoring case).
    players = nick(nick)
    # Next, favor player who matches with a preference for the most recent activity.
    players = any_nick(nick).order(:updated_at) if players.none?
    
    player = players.first
    
    if !!block && !!player
      yield(player)
    elsif !!(no_match = options[:no_match])
      no_match.call
    else
      player
    end
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
  
  def ban!(reason = '', options = {announce: false})
    Player.play_sound(nick, 'not_authorised') and sleep 5
    Player.execute("ban #{nick} #{reason}")

    if options[:announce]
      Player.play_sound('@a', 'not_authorised')
      if reason.present?
        Player.say('@a', "#{nick} has been banned, reason: #{reason}", as: 'Server', color: 'red')
      else
        Player.say('@a', "#{nick} has been banned", as: 'Server', color: 'red')
      end
    end
  end
  
  def pardon!
    result = Player.execute("pardon #{nick}")
    
    if result == "Could not unban player #{nick}" && !!last_nick
      alt_result = Player.execute("pardon #{last_nick}")
      if alt_result == "Could not unban player #{last_nick}"
        return "Could not unban player #{nick} or #{last_nick}"
      end
      result = alt_result
    end
    
    result
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
  
  def current_location
    response = Player.tp(nick, '~ ~ ~')
    
    reload.last_location
  end
  
  def current_pos
    [$1.to_i, $2.to_i, $3.to_i] if current_location =~ /^x=([\-0-9]+),y=([\-0-9]+),z=([\-0-9]+)$/
  end

  def last_pos
    [$1.to_i, $2.to_i, $3.to_i] if last_location =~ /^x=([\-0-9]+),y=([\-0-9]+),z=([\-0-9]+)$/
  end
  
  def update_biomes_explored
    self.biomes_explored = explore_all_biome_progress
  end

  def toggle_play_sounds!
    update_attribute(:play_sounds, !play_sounds) # no AR callbacks
  end
  
  def nearby_entity_data(radius = 1000)
    Server.entity_data(near_player: self, radius: radius)
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
  
  def above_exploration_threshold?
    Player.above_exploration_threshold.where(id: self).any?
  end
  
  def latest_country_code
    ips.last.cc if ips.any?
  end
private  
  def update_last_nick
    return unless !!id
    
    p = Player.find id
    
    unless p.nick.nil? || p.nick == last_nick
      update_attribute(:last_nick, p.nick) # no AR callbacks
    end
  end

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
