class RemoveSlackPreferences < ActiveRecord::Migration[6.1]
  class MigrationPreference < ActiveRecord::Base
    self.table_name = 'preferences'
  end

  def up
    MigrationPreference.where(key: %w[slack_api_key slack_group]).delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Slack credentials cannot be restored'
  end
end
