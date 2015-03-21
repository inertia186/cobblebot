class CreatePreferences < ActiveRecord::Migration
  def change
    create_table :preferences do |t|
      t.string :key
      t.string :value
      t.boolean :system, null: false, default: false
      t.timestamps null: false
    end
  end
end
