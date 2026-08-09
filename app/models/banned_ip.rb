class BannedIp
  attr_accessor :ip, :source, :reason, :expires_at, :created_at
  
  def self.banned_ips_path
    @banned_ip_path ||= "#{ServerProperties.path_to_server}/banned-ips.json"
  end
  
  def self.banned_ips_data
    JSON[File.read banned_ips_path] if File.exist? banned_ips_path
  end
  
  def self.find(options = {})
    return nil if options[:ip].blank?

    data = Array(banned_ips_data).find { |entry| options[:ip] == entry['ip'] }
    return nil unless data

    BannedIp.new(ip: data['ip'], source: data['source'], reason: data['reason'], expires_at: data['expires'], created_at: data['created'])
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
