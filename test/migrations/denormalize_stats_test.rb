require 'test_helper'
require Rails.root.join('db/migrate/20150913064149_denormalize_stats')

class DenormalizeStatsTest < ActiveSupport::TestCase
  def test_up_selects_and_backfills_every_uninitialized_player
    players = 2.times.map do |index|
      stats = Struct.new(:leave_game, :deaths, :mob_kills, :time_since_death, :player_kills)
        .new(index + 1, index + 2, index + 3, index + 4, index + 5)
      Object.new.tap do |player|
        player.define_singleton_method(:stat) { stats }
        player.define_singleton_method(:update_columns) { |values| @updates = values }
        player.define_singleton_method(:updates) { @updates }
      end
    end
    relation = Object.new
    relation.define_singleton_method(:count) { players.length }
    relation.define_singleton_method(:find_each) { |&block| players.each(&block) }
    selected = nil
    migration = DenormalizeStats.new

    Player.stub(:where, ->(conditions) { selected = conditions; relation }) do
      migration.stub(:add_column, nil) { capture_io { migration.up } }
    end

    assert_equal({
      leave_game: 0,
      deaths: 0,
      mob_kills: 0,
      time_since_death: 0,
      player_kills: 0
    }, selected)
    assert_equal [1, 2], players.map { |player| player.updates.fetch(:leave_game) }
    assert_equal [5, 6], players.map { |player| player.updates.fetch(:player_kills) }
  end

  def test_backfill_updates_all_stats_together
    stats = Struct.new(:leave_game, :deaths, :mob_kills, :time_since_death, :player_kills)
      .new(1, 2, 3, 4, 5)
    player = Object.new
    player.define_singleton_method(:stat) { stats }
    updates = nil
    player.define_singleton_method(:update_columns) { |values| updates = values }

    DenormalizeStats.new.send(:backfill_stats, player)

    assert_equal({
      leave_game: 1,
      deaths: 2,
      mob_kills: 3,
      time_since_death: 4,
      player_kills: 5
    }, updates)
  end

  def test_backfill_propagates_unexpected_stat_failures
    failure = RuntimeError.new('stats unavailable')
    player = Object.new
    player.define_singleton_method(:stat) { raise failure }
    player.define_singleton_method(:update_columns) { flunk 'must not write partial zero values' }

    error = assert_raises(RuntimeError) do
      DenormalizeStats.new.send(:backfill_stats, player)
    end

    assert_same failure, error
  end
end
