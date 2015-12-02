require 'test_helper'

class PvpTest < ActiveSupport::TestCase
  def setup
  end

  def test_record
    inertia186 = players(:inertia186)
    resnullius = players(:resnullius)

    pvp = Message::Pvp.record(body: 'inertia186 was killed by resnullius using Magic', created_at: Time.now)

    assert_equal inertia186, pvp.recipient
    assert_equal resnullius, pvp.author
  end
end
