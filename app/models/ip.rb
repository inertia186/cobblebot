require 'cgi'
require 'ipaddr'
require 'open3'

class Ip < ActiveRecord::Base
  attr_accessor :no_cc_lookup

  belongs_to :player
  
  validates_uniqueness_of :address, scope: :player
  validate :address_must_be_an_ip
  
  scope :query, lambda { |query|
    q = "%#{query}%"
    
    clause = <<-DONE
      ips.address LIKE ?
      OR ips.origin LIKE ?
      OR (player_id IN (?))
      OR ips.cc LIKE ?
    DONE
    where(clause, q, q, Player.query(query).select(:id), q)
  }
  
  after_validation do
    if new_record? && errors[:address].empty?
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
    cc = state = city = nil

    begin
      canonical_address = IPAddr.new(ip_address).to_s
      
      if (key = Preference.db_ip_api_key).present?
        encoded_key = CGI.escape(key)
        encoded_address = CGI.escape(canonical_address)
        url = "https://api.db-ip.com/v2/#{encoded_key}/#{encoded_address}"
        response = Net::HTTP.get_response(URI.parse(url))
        if response.is_a?(Net::HTTPSuccess)
          json = JSON.parse(response.body)
          cc = json['countryCode']
          state = json['stateProv']
          city = json['city']
        end
      end
    
      if cc.nil? # Fallback to ip2cc shell command.
        cc_result, _error, status = Open3.capture3('ip2cc', canonical_address)
        return false unless status.success?
    
        cc_result = cc_result.split('Country: ')[1]
        return false if cc_result.nil?
    
        cc = cc_result.split(' ')[0]
      end

      return false unless cc.is_a?(String) && cc.match?(/\A[A-Z]{2}\z/)

      result = {
        country: cc,
        state: state.is_a?(String) ? state : nil,
        city: city.is_a?(String) ? city : nil
      }
      Ip.where(cc: nil, address: ip_address).update_all(
        cc: result[:country], state: result[:state], city: result[:city]
      )
    rescue StandardError => e
      Rails.logger.error "Problem looking up country code for #{ip_address}: #{e.inspect}"
      return false
    end

    result
  end

  def address_must_be_an_ip
    IPAddr.new(address.to_s)
  rescue IPAddr::InvalidAddressError
    errors.add(:address, 'must be a valid IP address')
  end
end
