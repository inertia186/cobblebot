require 'test_helper'
require Rails.root.join('db/migrate/20260802000000_remove_slack_preferences').to_s

class RemoveSlackPreferencesTest < ActiveSupport::TestCase
  def test_up_deletes_only_slack_preferences
    Preference.create!(key: 'slack_api_key', value: 'test-token')
    Preference.create!(key: 'slack_group', value: 'test-group')
    Preference.create!(key: 'migration_control', value: 'keep-me')

    RemoveSlackPreferences.new.migrate(:up)

    assert_equal 0, Preference.where(key: %w[slack_api_key slack_group]).count
    assert_equal 'keep-me', Preference.find_by!(key: 'migration_control').value
  end

  def test_down_is_irreversible
    assert_raises ActiveRecord::IrreversibleMigration do
      RemoveSlackPreferences.new.migrate(:down)
    end
  end
end
