class CreateServerCallbacks < ActiveRecord::Migration
  def change
    create_table :server_callbacks do |t|
      t.string :type
      t.string :name, null: false
      t.string :pattern, null: false
      t.string :pretty_pattern
      t.text :last_match
      t.text :command, null: false
      t.text :pretty_command
      t.text :last_command_output
      t.timestamp :ran_at
      t.timestamp :error_flag_at
      t.string :cooldown, null: false, default: '+0 seconds'
      t.boolean :enabled, null: false, default: true
      t.boolean :system, null: false, default: false
      t.string :help_doc_key
      t.string :help_doc
      t.timestamps null: false
    end
  end
end
