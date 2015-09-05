class ServerCallback::AchievementAnnouncement < ServerCallback::ServerEntry
  def self.for_handling(line)
    line =~ REGEX_ACHIEVEMENT_ANNOUNCEMENT
  end
  
  def self.entry(line, options)
    segments = line.split(' ')
    nick = segments[3]
    message = segments[3..-1].join(' ')

    [nick, message, line, options]    
  end
end
