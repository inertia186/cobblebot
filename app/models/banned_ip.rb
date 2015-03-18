class BannedIP
  attr_accessor :ip, :source, :reason, :expires_at, :created_at
  
  def self.banned_ips_path
    @banned_ip_path ||= "#{ServerProperties.path_to_server}/banned-ips.json"
  end
  
  def self.banned_ips_data
    JSON[File.read banned_ips_path] if File.exists? banned_ips_path
  end
  
  def self.find(options = {})
    banned_ips_data.each do |data|
      if options[:ip] == data['ip']
        return BannedIP.new(ip: data['uuid'], source: data['source'], reason: data['reason'], expires_at: data['expires'], created_at: data['created'])
      end
    end
    
    nil
  end
  
  def initialize(options = {})
    self.ip = options[:ip]
    self.source = options[:source]
    self.reason = options[:reason]
    unless options[:expires_at] == 'forever'
      self.expires_at = Time.parse(options[:expires_at])
    end
    self.created_at = Time.parse(options[:created_at])
  end
end