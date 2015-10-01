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
  scope :shall_update_stats, lambda { |shall_update_stats = true| where(shall_update_stats: shall_update_stats) }
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
  scope :last_chat_after, lambda { |after|
    where("last_chat_at > ?", after)
  }
  scope :with_pvp_counts, -> {
    select("*, ( SELECT COUNT(*) FROM messages pvp_losses WHERE pvp_losses.type IN ('Message::Pvp') AND pvp_losses.recipient_type = 'Player' AND pvp_losses.recipient_id = players.id ) AS pvp_losses_count").
      select("*, ( SELECT COUNT(*) FROM messages pvp_wins WHERE pvp_wins.type IN ('Message::Pvp') AND pvp_wins.author_type = 'Player' AND pvp_wins.author_id = players.id ) AS pvp_wins_count")
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
  scope :has_pvp_wins, lambda { |has_pvp_wins = true|
    joins(:pvp_wins).uniq.tap do |r|
      return has_pvp_wins ? r : where.not(id: r)
    end
  }
  scope :has_pvp_losses, lambda { |has_pvp_losses = true|
    joins(:pvp_losses).uniq.tap do |r|
      return has_pvp_losses ? r : where.not(id: r)
    end
  }
  scope :has_ips, lambda { |has_ips = true|
    joins(:ips).uniq.tap do |r|
      return has_ips ? r : where.not(id: r)
    end
  }
  scope :has_reputations, lambda { |has_reputations = true|
    joins(:reputations).uniq.tap do |r|
      return has_reputations ? r : where.not(id: r)
    end
  }
  scope :has_inverse_reputations, lambda { |has_inverse_reputations = true|
    joins(:inverse_reputations).uniq.tap do |r|
      return has_inverse_reputations ? r : where.not(id: r)
    end
  }
  scope :has_donations, lambda { |has_donations = true|
    joins(:donations).uniq.tap do |r|
      return has_donations ? r : where.not(id: r)
    end
  }
  scope :has_quotes, lambda { |has_quotes = true|
    joins(:quotes).uniq.tap do |r|
      return has_quotes ? r : where.not(id: r)
    end
  }

  has_many :links, as: :actor
  has_many :messages, -> { where(type: nil) }, as: :recipient
  has_many :sent_messages, -> { where(type: nil) }, class_name: 'Message', as: :author
  has_many :tips, class_name: 'Message::Tip', as: :author
  has_many :topics, class_name: 'Message::Topic', as: :author
  has_many :pvp_wins, class_name: 'Message::Pvp', as: :author
  has_many :pvp_losses, class_name: 'Message::Pvp', as: :recipient
  has_many :ips
  has_many :mutes
  has_many :inverse_mutes, foreign_key: 'muted_player_id', class_name: 'Mute'
  has_many :muted_players, through: :mutes
  has_many :reputations, foreign_key: 'trustee_id', class_name: 'Reputation'
  has_many :rating_players, through: :reputations, source: :truster
  has_many :inverse_reputations, foreign_key: 'truster_id', class_name: 'Reputation'
  has_many :rated_players, through: :inverse_reputations, source: :trustee
  has_many :donations, class_name: 'Message::Donation', as: :author
  has_many :quotes, class_name: 'Message::Quote', as: :author

  before_save :update_stats
  before_save :update_last_nick, if: :nick_changed?

  def self.max_explore_all_biome_progress
    all.map(&:explore_all_biome_progress).map(&:to_i).max
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

  # Level I trust is the sum of direct trust for this player by a truster.
  # Level II trust is the sum of all trust for this player by those the truster trusts (through recursion).
  def reputation_sum(options = {level: 'I'})
    truster = options[:truster]
    return unless !!truster
    
    case options[:level]
    when 'I'
      reputation = truster.inverse_reputations.find_by_trustee_id(self)
      if !!reputation
        reputation.rate
      else
        0
      end
    when 'II'
      sum = 0
      
      truster.inverse_reputations.where.not(trustee: self).find_each do |reputation|
        sum = sum + reputation_sum(level: 'I', truster: reputation.trustee)
      end
        
      sum
    end
  end

  def players_with_same_ip(options = {})
    a = options[:except_address] || []
    o = options[:except_origin] || []
    
    other_ips = Ip.where(address: ips.where.not(address: a, origin: o).
      select(:address)).
      where.not(player_id: id)
      
    Player.where(id: other_ips.distinct(:player_id).select(:player_id))
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
    Time.at([last_chat_at.to_i, last_login_at.to_i, last_logout_at.to_i, updated_at.to_i].max)
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
  
  def hours_since_death
    "%.2f hours" % (time_since_death / 60.0 / 60.0 / 24.0)
  end
  
  # All kills, mobs + players
  def total_kills
    mob_kills + player_kills
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
  
  def current_block_type
    return if (pos = current_pos).nil?
    
    Player.execute("testforblock #{pos[0]} #{pos[1]} #{pos[2]} minecraft:air")
  end

  def last_block_type
    return if (pos = last_pos).nil?
    
    Player.execute("testforblock #{pos[0]} #{pos[1]} #{pos[2]} minecraft:air")
  end
  
  def update_stats
    self.shall_update_stats = true
  end

  # This method is not instant, so it's best if it is kicked off from a worker.
  def update_stats!
    options = {
      biomes_explored: explore_all_biome_progress,
      leave_game: (stat.leave_game rescue 0),
      deaths: (stat.deaths rescue 0),
      mob_kills: (stat.mob_kills rescue 0),
      time_since_death: (stat.time_since_death rescue 0),
      player_kills: (stat.player_kills rescue 0),
      shall_update_stats: false
    }
    
    update_columns(options) if persisted? # no AR callbacks
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

  # This will return the player's nick plus any additional information about them.
  #
  # http://wiki.vg/Mojang_API#UUID_-.3E_Profile_.2B_Skin.2FCape
  def profile
    _uuid = uuid.gsub(/-/, '')
    url = "https://sessionserver.mojang.com/session/minecraft/profile/#{_uuid}"
    response = Net::HTTP.get_response(URI.parse(url))
    json = JSON.parse(response.body)
  end

  # Returns all the nicks this player has used in the past and the one they are using currently.
  #
  # http://wiki.vg/Mojang_API#UUID_-.3E_Name_history
  def nick_history
    _uuid = uuid.gsub(/-/, '')
    url = "https://api.mojang.com/user/profiles/#{_uuid}/names"
    response = Net::HTTP.get_response(URI.parse(url))
    json = JSON.parse(response.body)
  end
  
  # To check if a player has voted or not in the last 24 hours.
  def mmp_vote_status
    url = "http://minecraft-mp.com/api/?object=votes&element=claim&key=#{Preference.mmp_api_key}&username=#{nick}"
    response = Net::HTTP.get_response(URI.parse(url))
    # 0	Not found
    # 1	Has voted and not claimed
    # 2	Has voted and claimed
    case response.body
    when "0"
      :not_found
    when "1"
      :has_voted_and_not_claimed
    when "2"
      :has_voted_and_claimed
    else
      :unknown
    end
  end
  
  # To set a vote as claimed for a player.
  def mmp_vote_claim!
    uri =     uri = URI.parse('http://minecraft-mp.com/api/')
    options = {
      action: 'post',
      object: 'votes',
      element: 'claim',
      key: Preference.mmp_api_key,
      username: nick
    }
    response = Net::HTTP.post_form(uri, options)
    # 0  Vote has not been claimed
    # 1  Vote has been claimed
    response.body == "1"
  end

  def last_pvp_loss_has_quote?
    return true if pvp_losses.none?
    
    !!(pvp = pvp_losses.last) && quotes.where('messages.created_at > ?', pvp.created_at).any?
  end
  
  def last_pvp_win_has_quote?
    return true if pvp_wins.none?

    !!(pvp = pvp_wins.last) && quotes.where('messages.created_at > ?', pvp.created_at).any?
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
