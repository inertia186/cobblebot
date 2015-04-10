require 'rcon/rcon'

module Commandable
  extend ActiveSupport::Concern
  
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
      end
    
      nil
    end
  
    def execute(command)
      try_max.times do
        case command_scheme
        when 'rcon'
          return rcon.command(command)
        when 'multiplexor'
          # TODO Something like: `bash -c "screen -p 0 -S minecraft -X eval 'stuff \"#{command}\"\015'"`
          return
        else
          raise StandardError.new("Preference.command_scheme not recognized")
        end
      end
    rescue StandardError => e
      Rails.logger.warn e.inspect
      sleep retry_sleep
      ServerProperties.reset_vars
      reset_vars
    end
    
    def kick(nick, reason = "Have A Nice Day")
      execute "kick #{nick} #{reason}"
    end
  
    def escape(message)
      message.gsub(/"/, "\"").force_encoding('US-ASCII')
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
    
      _a = a.split('[')[1]
      _a = _a.split(']')[0] if _a
      _b = b.split('[')[1]
      _b = _b.split(']')[0] if _b
      _c = [_a, _b].reject(&:nil?)

      return "@#{a[1]}" if _c.empty?
      return "@#{a[1]}[#{_c.join(',')}]"
    end
  end
end