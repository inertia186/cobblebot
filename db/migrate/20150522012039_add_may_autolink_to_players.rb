class AddMayAutolinkToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :may_autolink, :boolean, null: false, default: true
  end
end
