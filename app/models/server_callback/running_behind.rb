class ServerCallback::RunningBehind < ServerCallback::ServerEntry
  def self.for_handling(line)
    line =~ REGEX_RUNNING_BEHIND
  end
  
  def self.entry(line, options)
    segments = line.split(' ')
    message = segments[3..-1].join(' ')

    [nil, message, line, options]    
  end
end
