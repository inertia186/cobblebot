class Ip < ActiveRecord::Base
  belongs_to :player
  
  validates_uniqueness_of :address, scope: :player
  
  scope :query, lambda { |query|
    clause = <<-DONE
      ips.origin LIKE ?
      OR (player_id IN (?))
      OR ips.cc IN (?)
    DONE
    where(clause, query, Player.search_any_nick(query).select(:id), query)
  }
  
  after_validation do
    return unless new_record?
    salt = Preference.origin_salt.strip
    hash = Digest::MD5.hexdigest "#{salt} :: #{address.split('.')[0..2].join('.')}\n"
    self.origin = hash[0..2]
    self.cc = Ip.update_cc(address)
  end
private
  def self.update_cc(ip_address)
    cc_result = `ip2cc #{ip_address}`
    return false if cc_result.nil?
    
    cc_result = cc_result.split('Country: ')[1]
    return false if cc_result.nil?
    
    cc = cc_result.split(' ')[0]
    
    Ip.where(cc: nil).where(address: ip_address).update_all("cc = '#{cc}'")
    
    cc
  end
end
