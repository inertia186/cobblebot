class ServerCallback::DeathAnnouncement < ServerCallback::ServerEntry
  def self.for_handling(line)
    regex = Regexp.union(
      /was.*by/,
      /was killed trying to hurt/,
      /was burnt to a crisp/,
      /tried to swim in lava/,
      /was killed.*using magic/,
      /^[a-zA-A0-9_]+ fell out of the world/,
      /was knocked into the void/,
      /^[a-zA-Z0-9_]+ fell from a high place/,
      /was doomed to fall/,
      /hit the ground too hard/,
      /starved to death/,
      /withered away/,
      /was killed by/,
      /was pricked to death/,
      /was squashed by a/,
      /was fireballed/,
      /starved to death/,
    )
    
    regex.match(line) &&
      !(line =~ REGEX_PLAYER_CHAT ||
        line =~ REGEX_PLAYER_EMOTE ||
        line =~ REGEX_ACHIEVEMENT_ANNOUNCEMENT)
  end
  
  def self.entry(line, options)
    segments = line.split(' ')
    nick = segments[3]
    message = segments[3..-1].join(' ')

    [nick, message, line, options]    
  end
end
