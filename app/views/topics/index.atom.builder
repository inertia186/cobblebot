atom_feed do |feed|
  feed.body "#{ServerProperties.level_name.titleize} Topics"
  feed.updated @topics.maximum(:created_at)
  
  @topics.each do |topic|
    feed.entry topic, url: topics_path do |entry|
      entry.title topic.body
      entry.content topic.body
      if !!topic.author
        entry.author do |author|
          author.name topic.author.nick
        end
      end
    end
  end
end
