class CreateServerCallbacks < ActiveRecord::Migration
  def change
    create_table :server_callbacks do |t|
      t.string :name, null: false
      t.string :pattern, null: false
      t.string :match_scheme, null: false, default: 'any'
      t.text :command, null: false
      t.boolean :enabled, null: false, default: '1'
    end
  end
end
