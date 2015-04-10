module Emotable
  extend ActiveSupport::Concern
  extend Commandable
  
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
