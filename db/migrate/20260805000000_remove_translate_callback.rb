class RemoveTranslateCallback < ActiveRecord::Migration[7.0]
  class MigrationServerCallback < ActiveRecord::Base
    self.table_name = 'server_callbacks'
    self.inheritance_column = :_type_disabled
  end

  def up
    MigrationServerCallback.where(
      type: 'ServerCallback::PlayerCommand',
      name: 'Translate',
      system: true
    ).delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      'The retired Translate callback cannot be restored automatically'
  end
end
