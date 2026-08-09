require 'test_helper'
require Rails.root.join('db/migrate/20260809000000_make_mute_pairs_unique')

class MakeMutePairsUniqueTest < ActiveSupport::TestCase
  def test_up_removes_duplicate_rows_before_adding_the_unique_index
    migration = MakeMutePairsUnique.new
    relation = duplicate_relation(kept_id: 10)
    grouped = Object.new
    grouped.define_singleton_method(:having) do |clause|
      raise "unexpected HAVING clause: #{clause}" unless clause == 'COUNT(*) > 1'

      self
    end
    grouped.define_singleton_method(:pluck) do |*columns|
      expected = [:player_id, :muted_player_id]
      raise "unexpected pluck columns: #{columns.inspect}" unless columns == expected

      [[1, 2]]
    end
    index_calls = []

    MakeMutePairsUnique::MuteRecord.stub(:group, ->(*columns) {
      assert_equal [:player_id, :muted_player_id], columns
      grouped
    }) do
      MakeMutePairsUnique::MuteRecord.stub(:where, ->(attributes) {
        assert_equal({player_id: 1, muted_player_id: 2}, attributes)
        relation
      }) do
        migration.stub(:remove_index, ->(table, name:) {
          index_calls << [:remove, table, name]
        }) do
          migration.stub(:add_index, ->(table, columns, **options) {
            index_calls << [:add, table, columns, options]
          }) do
            migration.up
          end
        end
      end
    end

    assert_equal 10, relation.minimum_id
    assert_equal({id: 10}, relation.excluded_attributes)
    assert relation.deleted
    assert_equal [
      [:remove, :mutes, MakeMutePairsUnique::INDEX_NAME],
      [:add, :mutes, [:player_id, :muted_player_id], {
        unique: true,
        name: MakeMutePairsUnique::INDEX_NAME
      }]
    ], index_calls
  end

  def test_down_restores_the_nonunique_index
    migration = MakeMutePairsUnique.new
    index_calls = []

    migration.stub(:remove_index, ->(table, name:) {
      index_calls << [:remove, table, name]
    }) do
      migration.stub(:add_index, ->(table, columns, **options) {
        index_calls << [:add, table, columns, options]
      }) do
        migration.down
      end
    end

    assert_equal [
      [:remove, :mutes, MakeMutePairsUnique::INDEX_NAME],
      [:add, :mutes, [:player_id, :muted_player_id], {
        name: MakeMutePairsUnique::INDEX_NAME
      }]
    ], index_calls
  end

private
  def duplicate_relation(kept_id:)
    Object.new.tap do |relation|
      relation.define_singleton_method(:minimum_id) { @minimum_id }
      relation.define_singleton_method(:excluded_attributes) { @excluded_attributes }
      relation.define_singleton_method(:deleted) { @deleted }
      relation.define_singleton_method(:minimum) do |column|
        raise "unexpected minimum column: #{column}" unless column == :id

        @minimum_id = kept_id
      end
      relation.define_singleton_method(:where) do
        @not_scope ||= Object.new.tap do |scope|
          owner = self
          scope.define_singleton_method(:not) do |attributes|
            owner.instance_variable_set(:@excluded_attributes, attributes)
            owner
          end
        end
      end
      relation.define_singleton_method(:delete_all) { @deleted = true }
    end
  end
end
