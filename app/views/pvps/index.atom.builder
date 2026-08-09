atom_feed do |feed|
  feed.title "#{ServerProperties.level_name.titleize} PVPs"
  feed.updated @pvps.maximum(:created_at) || Time.current
  
  @pvps.each do |pvp|
    feed.entry pvp, url: pvps_path do |entry|
      participants = [pvp.recipient&.nick, pvp.author&.nick].compact
      entry.title participants.any? ? participants.join(' vs. ') : pvp.body
      entry.content pvp.body
      if !!pvp.author
        entry.author do |author|
          author.name pvp.author.nick
        end
      end
    end
  end
end
