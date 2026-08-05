require 'test_helper'

class ReputationTest < ActiveSupport::TestCase
  def setup
    @truster = players(:inertia186)
    @trustee = players(:Dinnerbone)
  end

  def test_valid_reputation_and_join_projection
    reputation = Reputation.create!(truster: @truster, trustee: @trustee, rate: 4)
    projected = Reputation.with_trustables.find(reputation.id)

    assert_equal @truster.uuid, projected.trusters_uuid
    assert_equal @truster.nick, projected.trusters_nick
    assert_equal @trustee.uuid, projected.trustees_uuid
    assert_equal @trustee.nick, projected.trustees_nick
  end

  def test_requires_both_players_and_a_nonzero_bounded_integer_rate
    reputation = Reputation.new

    refute reputation.valid?
    assert_includes reputation.errors[:truster_id], "can't be blank"
    assert_includes reputation.errors[:trustee_id], "can't be blank"

    [-10, 0, 10].each do |rate|
      reputation = Reputation.new(truster: @truster, trustee: @trustee, rate: rate)
      refute reputation.valid?, "expected #{rate.inspect} to be rejected"
    end
  end

  def test_rejects_self_reputation_and_duplicate_pairs
    self_reputation = Reputation.new(truster: @truster, trustee: @truster, rate: 1)

    refute self_reputation.valid?
    assert_includes self_reputation.errors[:truster], "one cannot express a reputation for one's self"
    assert_includes self_reputation.errors[:trustee], "one cannot express a reputation for one's self"

    Reputation.create!(truster: @truster, trustee: @trustee, rate: 1)
    duplicate = Reputation.new(truster: @truster, trustee: @trustee, rate: 2)
    refute duplicate.valid?
  end
end
