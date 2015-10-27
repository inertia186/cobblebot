class Reputation < ActiveRecord::Base
  belongs_to :truster, class_name: 'Player'
  belongs_to :trustee, class_name: 'Player'

  scope :with_trustables, -> {
    joins('LEFT OUTER JOIN players trusters ON trusters.id = reputations.truster_id LEFT OUTER JOIN players trustees ON trusters.id = reputations.trustee_id').
      select('reputations.*, trusters.uuid AS trusters_uuid, trusters.nick AS trusters_nick, trustees.uuid AS trustees_uuid, trustees.nick AS trustees_nick')
  }
  
  validates :truster_id, presence: true
  validates :trustee_id, presence: true
  validates_uniqueness_of :truster, scope: :trustee
  validates_uniqueness_of :trustee, scope: :truster
  validates :rate, numericality: {
    greater_than_or_equal_to: -9,
    less_than_or_equal_to: 9,
    integer_only: true
  }, presence: true
  validates :rate, exclusion: { in: [0], message: "%{value} is not allowed" }
  validate do |record|
    if record.truster_id == record.trustee_id
      errors.add(:truster, 'one cannot express a reputation for one\'s self')
      errors.add(:trustee, 'one cannot express a reputation for one\'s self')
    end
  end
end