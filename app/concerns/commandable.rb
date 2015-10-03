require 'rcon/rcon'

module Commandable
  extend Runnable

  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    TRY_MAX = 5
    RETRY_SLEEP = 5
  
    def try_max
      Rails.env == 'test' ? 1 : TRY_MAX
    end
  
    def retry_sleep
      Rails.env == 'test' ? 0 : RETRY_SLEEP
    end
  
    def reset_vars
      @command_scheme = nil
      @rcon = nil
      @rcon_auth_success = nil
      @multiplexor = nil
    end
  
    def command_scheme
      return @command_scheme unless @command_scheme.nil?
      raise StandardError.new("Preference.command_scheme not initialized properly") if Preference.command_scheme.nil?
    
      @command_scheme ||= Preference.command_scheme
    end
  
    def rcon
      raise StandardError.new("RCON port not set.  To set, please modify server.properties and change rcon.port=25575") unless ServerProperties.rcon_port
      raise StandardError.new("RCON password not set.  To set, please modify server.properties and change rcon.password=") unless ServerProperties.rcon_password
      raise StandardError.new("RCON is disabled.  To enable rcon, please modify server.properties and change enable-rcon=false to enable-rcon=true and restart server.") unless ServerProperties.enable_rcon == 'true'

      try_max.times do

        if @rcon.nil? || @rcon_connected_at.nil? || @rcon_connected_at > 15.minutes.ago
          @rcon = RCON::Minecraft.new(ServerProperties.server_ip, ServerProperties.rcon_port)
          @rcon_connected_at = Time.now
          @rcon_auth_success = nil
        end

        begin
          return @rcon if @rcon_auth_success ||= @rcon.auth(ServerProperties.rcon_password)
        rescue Errno::ECONNREFUSED => e
          Rails.logger.warn e.inspect
          sleep retry_sleep
          ServerProperties.reset_vars
          reset_vars
        end
        
        break
      end
    
      nil
    end
  
    def execute(command, options = {try_max: try_max})
      _try_max = if options[:try_max].present?
        options[:try_max].to_i
      else
        try_max
      end
      
      _try_max = try_max if _try_max == 0
      
      _try_max.times do
        begin
          case command_scheme
          when 'rcon'
            return rcon.command(command)
          when 'multiplexor'
            # TODO Something like: `bash -c "screen -p 0 -S minecraft -X eval 'stuff \"#{command}\"\015'"`
            return
          else
            raise StandardError.new("Preference.command_scheme not recognized")
          end
        
          break
        rescue StandardError, Errno::ECONNRESET, TypeError => e
          Rails.logger.error e.inspect
          e.backtrace.each { |line| Rails.logger.error line }
          sleep retry_sleep
          ServerProperties.reset_vars
          reset_vars
        end
      end
      
      return nil
    end
    
    def kick(nick, reason = "Have A Nice Day")
      execute "kick #{nick} #{reason}"
    end
  
    def escape(message)
      message.gsub(/"/, "\\\"").force_encoding('US-ASCII')
    end
  
    def register(nick)
      player = Player.find_by_nick(nick)
      
      if player.nil?
        tell(nick, 'There was a problem and you were not registered.  Relog and try again.')
        return
      end
      
      if player.new?
        tell(nick, 'Not registered, too new.  Try again in 24 hours.')
        return 
      end

      unless player.above_exploration_threshold?
        tell(nick, 'Not registered, still too close to spawn.')
        return 
      end

      if player.registered?
        tell(nick, 'Already registered.')
        return 
      end

      if player.register!
        tell(nick, 'Registered.')
      else
        tell(nick, 'Unable to register at this time.  Try again later.')
      end
    end
    
    def unregister(nick)
      player = Player.find_by_nick(nick)

      if player.nil?
        tell(nick, 'There was a problem and you were not unregistered.  Relog and try again.')
        return
      end
      
      if player.registered?
        # TODO Currently, there is no support for unregistering.  Once the trust
        # system is better defined, maybe we can revisit this idea.
        tell(nick, 'Make up your mind.')
      else
        tell(nick, 'wut?')
      end
    end
  
    # The purpose of this method is to allow players to use limited selectors in
    # certain situations.
    #
    # Setting deep true allows this method to search for players using full
    # selector logic, like:
    #
    # @r[r=1000]
    #
    # The default is false because allowing players to express full selectors
    # can lead to security risks, possibly exposing server crash scenarios.
    #
    def sub_safe_selectors(text, options = {deep: false})
      text.sub!(/(@r\[.*\])/i, Server.player_nicks($1).sample.to_s) while text =~ /(@r\[.*\])/i && !!options[:deep]
      text.sub!(/@r/i, Server.player_nicks.sample) while text =~ /@r/i
      text.sub!(/(@p\[.*\])/i, Server.player_nicks($1).sample.to_s) while text =~ /(@p\[.*\])/i && !!options[:deep]
      text.sub!(/@p/i, Server.player_nicks.sample) while text =~ /@p/i
      text.sub!(/(@a\[.*\])/i, Server.player_nicks($1).sample.to_s) while text =~ /(@a\[.*\])/i && !!options[:deep]
      text.sub!(/@a/i, Server.player_nicks.sample) while text =~ /@a/i && !!options[:deep]
      text.sub!(/@a/i, 'everyone') while text =~ /@a/i
      text.sub!(/@e\[c=-1\]/i, 'Spy Chicken') while text =~ /@e\[c=-1\]/i
      text.sub!(/@e\[c=1\]/i, 'Spy Chicken') while text =~ /@e\[c=1\]/i
      text.sub!(/@e/i, 'Spy Chicken') while text =~ /@e/i
    
      text
    end
    
    # Imagine you have two selectors, for example:
    # 
    # a: @a[r=1000]
    #   -and-
    # b: @a[name=!inertia186]
    #
    # This method will merge them into:
    #
    # c: @a[r=1000,name=!inertia186]
    #
    def merge_selectors(a, b)
      raise "Cannot merge unlike selectors: @#{a[1]} .. @#{b[1]}" if a[1] != b[1]
      _a, _b = a.split('[')[1], b.split('[')[1]
      _a = _a.split(']')[0] if _a
      _b = _b.split(']')[0] if _b
      _c = [_a, _b].reject(&:nil?)

      return "@#{a[1]}" if _c.empty?
      return "@#{a[1]}[#{_c.join(',')}]"
    end
  end
end
