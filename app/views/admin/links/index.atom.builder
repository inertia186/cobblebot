atom_feed do |feed|
  feed.title "#{ServerProperties.level_name.titleize} Links"
  feed.updated @links.maximum(:created_at)
  
  @links.each do |link|
    feed.entry link, url: link.url do |entry|
      entry.title link.title
      entry.content content_tag :iframe, nil, width: 640, height: 480, src: link.embedded_url if link.can_embed?
      if !!link.actor
        entry.author do |author|
          author.name link.actor.nick
        end
      end
    end
  end
end