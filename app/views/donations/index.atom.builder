atom_feed do |feed|
  feed.title "#{ServerProperties.level_name.titleize} Donations"
  feed.updated @donations.maximum(:created_at) || Time.current
  
  @donations.each do |donation|
    feed.entry donation, url: donations_path do |entry|
      entry.title donation.body
      entry.content donation.body
      if !!donation.author
        entry.author do |author|
          author.name donation.author.nick
        end
      end
    end
  end
end
