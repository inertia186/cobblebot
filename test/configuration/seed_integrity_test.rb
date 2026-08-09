require 'test_helper'

class SeedIntegrityTest < ActiveSupport::TestCase
  def test_seed_records_fail_fast_inside_a_transaction
    assert_includes seeds, 'ActiveRecord::Base.transaction do'
    assert_includes seeds, 'method = :seed_create!'
    assert_includes seeds, 'record.save!'
    refute_includes seeds, 'method ||= :create'
    assert_match(/\nend\s*\z/, seeds)
  end

  def test_seed_helper_raises_on_invalid_records
    assert_raises(ActiveRecord::RecordInvalid) do
      ServerCallback.seed_create!(name: 'Invalid seed callback')
    end

    assert_nil ServerCallback.find_by(name: 'Invalid seed callback')
  end

  def test_fell_out_of_world_callback_accepts_uppercase_player_names
    pattern = %r{^[a-zA-Z0-9_]+ fell out of the world}

    assert_match pattern, 'Bob fell out of the world'
    assert_match pattern, 'alice fell out of the world'
    assert_includes seeds,
      "name: 'Fell Out of the World', pattern: \"/^[a-zA-Z0-9_]+ fell out of the world/\""
  end

  private

  def seeds
    @seeds ||= Rails.root.join('db/seeds.rb').read
  end
end
