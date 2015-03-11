include ApplicationHelper

class MinecraftServerLogHandler
  def self.handle(line)
    puts line
    
    if line.downcase =~ /@server version/
      say "CobbleBot version 0.0.1"
    end
  end
end