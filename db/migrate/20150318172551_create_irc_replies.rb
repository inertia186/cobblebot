class CreateIrcReplies < ActiveRecord::Migration
  def change
    create_table :irc_replies do |t|
      t.string :body
      t.timestamps null: false
    end
  end
end
