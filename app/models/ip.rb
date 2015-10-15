class Ip < ActiveRecord::Base
  attr_accessor :no_cc_lookup

  belongs_to :player
  
  validates_uniqueness_of :address, scope: :player
  
  scope :query, lambda { |query|
    q = "%#{query}%"
    
    clause = <<-DONE
      ips.address LIKE ?
      OR ips.origin LIKE ?
      OR (player_id IN (?))
      OR ips.cc IN (?)
    DONE
    where(clause, q, q, Player.query(query).select(:id), q)
  }
  
  after_validation do
    if new_record?
      salt = Preference.origin_salt.strip
      hash = Digest::MD5.hexdigest "#{salt} :: #{address.split('.')[0..2].join('.')}\n"
      self.origin = hash[0..2]
      unless !!no_cc_lookup
        result = Ip.update_cc(address)
        if !!result
          self.cc = result[:country]
          self.state = result[:state]
          self.city = result[:city]
        end
      end
    end
  end
  
  def self.cc_count(sort_order = :asc)
    result = where.not(cc: [nil, '??', '**']).group(:cc).count
    
    case sort_order
    when :asc
      result.sort_by { |c| c[1] }
    when :desc
      result.sort_by { |c| c[1] }.reverse
    else
      result
    end
  end
private
  def self.update_cc(ip_address)
    begin
      cc = nil, state = nil, city = nil
      
      if !!(key = Preference.db_ip_api_key)
        url = "http://api.db-ip.com/addrinfo?addr=#{ip_address}&api_key=#{key}"
        response = Net::HTTP.get_response(URI.parse(url))
        json = JSON.parse(response.body)
        cc = json['country']
        state = json['stateprov']
        city = json['city']
      end
    
      if cc.nil? # Fallback to ip2cc shell command.
        cc_result = `ip2cc #{ip_address}`
        return false if cc_result.nil?
    
        cc_result = cc_result.split('Country: ')[1]
        return false if cc_result.nil?
    
        cc = cc_result.split(' ')[0]
      end
    
      Ip.where(cc: nil).where(address: ip_address).update_all("cc = '#{cc}', state = '#{state}', city = '#{city}'")
    rescue StandardError => e
      Rails.logger.error "Problem looking up country code for #{ip_address}: #{e.inspect}"
    end

    {country: cc, state: state, city: city}
  end
end
