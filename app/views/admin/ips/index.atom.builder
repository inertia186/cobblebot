atom_feed do |feed|
  feed.title "#{ServerProperties.level_name.titleize} IP activity"
  latest_created_at = @ips.maximum(:created_at)
  feed.updated Time.zone.parse(latest_created_at) if latest_created_at

  @ips.each do |ip|
    feed.entry ip,
      url: admin_ips_url(address: ip.address),
      published: Time.zone.parse(ip.created_at),
      updated: Time.zone.parse(ip.created_at) do |entry|
      entry.title ip.address
      entry.content "Origin #{ip.origin}; country #{ip.cc || 'unknown'}"
      entry.author { |author| author.name(ip.player.nick) } if ip.player
    end
  end
end
