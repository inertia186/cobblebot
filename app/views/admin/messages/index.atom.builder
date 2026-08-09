atom_feed do |feed|
  feed.title "#{ServerProperties.level_name.titleize} Messages"
  feed.updated @messages.maximum(:created_at) || Time.current
  
  @messages.each do |message|
    feed.entry message, url: admin_message_path(message) do |entry|
      entry.title "By: #{message.author.nick rescue '[REDACTED]'}; To: #{message.recipient.nick rescue '[REDACTED]'}"
      entry.content message.body
      if !!message.author
        entry.author do |author|
          author.name message.author.nick
        end
      end
    end
  end
end
