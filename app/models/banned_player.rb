class BannedPlayer
  attr_accessor :uuid, :nick, :source, :reason, :expires_at, :created_at
  attr_accessor :fishbans
  
  def self.banned_players_path
    @banned_players_path ||= "#{ServerProperties.path_to_server}/banned-players.json"
  end
  
  def self.banned_players_data
    JSON[File.read banned_players_path] if File.exists? banned_players_path
  end
  
  def self.find(options = {})
    banned_players_data.each do |data|
      if options[:uuid] == data['uuid'] || options[:nick] == options['name']
        return BannedPlayer.new(uuid: data['uuid'], nick: data['name'], source: data['source'], reason: data['reason'], expires_at: data['expires'], created_at: data['created'])
      end
    end
    
    nil
  end
  
  def initialize(options = {})
    self.uuid = options[:uuid]
    self.nick = options[:nick]
    self.source = options[:source]
    self.reason = options[:reason]
    unless options[:expires_at] == 'forever'
      self.expires_at = Time.parse(options[:expires_at])
    end
    self.created_at = Time.parse(options[:created_at])
  end
  
  def fishbans
    return @fishbans if !!@fishbans
    
    begin
      agent = Mechanize.new
      agent.keep_alive = false
      agent.open_timeout = 5
      agent.read_timeout = 5
      agent.get "http://api.fishbans.com/bans/#{nick}"

      @fishbans = agent.page.body if agent.page
    rescue StandardError => e
      Rails.logger.error e.inspect
    end
  end
end