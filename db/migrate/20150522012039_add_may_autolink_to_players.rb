class AddMayAutolinkToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :may_autolink, :boolean, null: false, default: true
  end
end
