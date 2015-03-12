include ApplicationHelper

class MinecraftServerLogHandler
  def self.handle(line)
    begin
      puts "Handling: #{line}"

      if line =~ /^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: <[^<]+> /
        handle_chat(line)
      end
    rescue StandardError => e
      Rails.logger.warn e
    end
  end
  
  def self.handle_chat(line)
    if line =~ /@server version/i
      say "CobbleBot version 0.0.1"
      link "@a", "http://github.com/inertia186/cobblebot"
    elsif line =~ /http.*/i
      text = line.gsub(/http/i, 'http')
      url = text.split('http')[1]
      return unless url
      
      url = "http#{url.split(' ')[0]}"
      link "@a", url if !!url.split('://')[1]
    end
  end
end