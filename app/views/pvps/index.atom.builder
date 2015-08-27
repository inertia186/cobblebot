atom_feed do |feed|
  feed.body "#{ServerProperties.level_name.titleize} Topics"
  feed.updated @pvps.maximum(:created_at)
  
  @pvps.each do |pvp|
    feed.entry pvp, url: pvps_path do |entry|
      entry.title "#{pvp.recipient.nick} vs. #{pvp.author.nick}"
      entry.content pvp.body
      if !!pvp.author
        entry.author do |author|
          author.name pvp.author.nick
        end
      end
    end
  end
end
