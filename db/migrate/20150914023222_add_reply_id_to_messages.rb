class AddReplyIdToMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :messages, :reply_id, :integer
  end
end
