class AddUuidToMessages < ActiveRecord::Migration
  def up
    add_column :messages, :uuid, :string
    
    messages = Message.where(uuid: nil)
    count = messages.count
    puts "Creating UUID for #{count} messages.  ^C to safely retry this migration later."
    
    messages.find_each do |message|
      message.update_column(:uuid, SecureRandom.uuid)

      print '.'
    end

    puts "\nDone."
    
    change_column :messages, :uuid, :string, null: false
  end
  
  def down
    remove_column :messages, :uuid
  end
end
