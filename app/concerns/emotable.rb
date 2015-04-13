module Emotable
  extend Commandable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    ## Simuates /me
    def emote(selector, message, options = {color: 'white', as: 'Server'})
      return if selector.nil?
    
      execute <<-DONE
        tellraw #{selector} [{ "color": "white", "text": "* #{options[:as]} "}, { "color": "#{options[:color]}", "text": "#{message}" }]
      DONE
    end
  end
end
