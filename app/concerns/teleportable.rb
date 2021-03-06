module Teleportable
  extend Commandable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def tp(selector, destination, options = {})
      return if selector.nil?
      return if !!options[:pretend]
    
      player = Player.find_by_nick(selector)
    
      if !!player
        response = execute "tp #{player.nick} #{destination}"
        return if response.nil?
        return unless response
        return if response == 'The entity UUID provided is in an invalid format'

        if response.respond_to?(:split)
          pos = response.split(' ')[3..-1].join(' ').split(/[\s,]+/)
          player.update_attributes(last_location: "x=#{pos[0].to_i},y=#{pos[1].to_i},z=#{pos[2].to_i}")
        end
      else
        response = execute "tp #{selector} #{destination}"
        return if response == 'The entity UUID provided is in an invalid format'
      end
    
      response
    end
  end
end
