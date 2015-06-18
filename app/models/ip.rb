class Ip < ActiveRecord::Base
  belongs_to :player
  
  validates_uniqueness_of :address, scope: :player, on: :address_changed?
  
  scope :query, lambda { |query|
    clause = <<-DONE
      ips.origin LIKE ?
      OR (player_id IN (?))
    DONE
    where(clause, query, Player.search_any_nick(query).select(:id))
  }
  
  after_validation do
    return unless new_record?
    salt = Preference.origin_salt.strip
    hash = Digest::MD5.hexdigest "#{salt} :: #{address.split('.')[0..2].join('.')}\n"
    self.origin = hash[0..2]
  end
end
