require 'test_helper'

class PvpTest < ActiveSupport::TestCase
  def test_record
    inertia186 = players(:inertia186)
    resnullius = players(:resnullius)

    pvp = Message::Pvp.record(body: 'inertia186 was killed by resnullius using Magic', created_at: Time.now)

    assert_equal inertia186, pvp.recipient
    assert_equal resnullius, pvp.author
  end

  def test_quote_helpers_fall_back_only_when_no_later_quote_exists
    pvp = messages(:dinnerbone_killed_resnullius)
    pvp.recipient.update!(last_chat: 'loser fallback')
    pvp.author.update!(last_chat: 'winner fallback')

    assert_equal 'loser fallback', pvp.loser_quote
    assert_equal 'winner fallback', pvp.winner_quote
  end

  def test_quote_helpers_propagate_query_failures
    pvp = messages(:dinnerbone_killed_resnullius)
    error = ActiveRecord::StatementInvalid.new('simulated query failure')

    pvp.recipient.stub(:quotes, -> { raise error }) do
      assert_raises(ActiveRecord::StatementInvalid) { pvp.loser_quote }
    end
    pvp.author.stub(:quotes, -> { raise error }) do
      assert_raises(ActiveRecord::StatementInvalid) { pvp.winner_quote }
    end
  end
end
