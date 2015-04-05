class ServerCallback::AnyEntry < ServerCallback
  def self.handle(line, options = {})
    return unless line =~ REGEX_ANY
    any_result = nil

    segments = line.split(' ')
    message = segments[3..-1].join(' ')

    ready.find_each do |callback|
      result = callback.handle_entry(nil, message, line, options)
      any_result ||= result
    end
    
    any_result
  end
end