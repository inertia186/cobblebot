class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :type
      t.text :body, null: false
      t.text :keywords
      t.string :recipient_term, null: false
      t.string :recipient_type
      t.integer :recipient_id
      t.string :author_type
      t.integer :author_id
      t.timestamp :read_at
      t.timestamps null: false
    end
  end
end
