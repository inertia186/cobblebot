require 'test_helper'

class MuteTest < ActiveSupport::TestCase
  def setup
    @player = players(:inertia186)
    @muted_player = players(:Dinnerbone)
  end

  def test_persisted_mute_can_be_saved_again
    mute = Mute.create!(player: @player, muted_player: @muted_player)

    assert mute.save
  end

  def test_rejects_duplicate_and_self_mutes
    Mute.create!(player: @player, muted_player: @muted_player)

    refute Mute.new(player: @player, muted_player: @muted_player).valid?
    refute Mute.new(player: @player, muted_player: @player).valid?
  end

  def test_database_rejects_duplicate_mute_pairs
    mute = Mute.create!(player: @player, muted_player: @muted_player)

    assert_raises ActiveRecord::RecordNotUnique do
      Mute.insert_all!([{
        player_id: mute.player_id,
        muted_player_id: mute.muted_player_id,
        created_at: Time.current
      }])
    end
  end

  def test_missing_associations_add_errors_without_raising
    mute = Mute.new

    refute mute.valid?
    assert_predicate mute.errors[:player], :present?
    assert_predicate mute.errors[:muted_player], :present?
  end
end
