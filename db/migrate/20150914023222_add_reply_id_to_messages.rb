class AddReplyIdToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :reply_id, :integer
  end
end
