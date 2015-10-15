class AddAutotranslateToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :autotranslate, :string, default: nil
  end
end
