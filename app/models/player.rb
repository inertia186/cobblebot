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

  has_many :links, as: :actor

  def self.max_explore_all_biome_progress
    all.map(&:explore_all_biome_progress).map(&:to_i).max
  end

  def to_param
    "#{id}-#{nick.parameterize}"
  end
  
  def registered?
    !!registered_at
  end

  def vetted?
    !!vetted_at
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
    achievements.explore_all_biomes['progress'].count if player_data rescue 0
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
