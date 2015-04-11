class ServerCallback::AnyEntry < ServerCallback
  def self.for_handling(line)
    line =~ REGEX_ANY
  end

  def self.entry(line, options)
    segments = line.split(' ')
    message = segments[3..-1].join(' ')
  
    [nil, message, line, options]
  end
end