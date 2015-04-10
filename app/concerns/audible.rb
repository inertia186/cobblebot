module Audible
  extend ActiveSupport::Concern
  extend Commandable
  
  module ClassMethods
    def play_sound(selector, sound, options = {volume: '', pitch: ''})
      if (disabled = Server.players.play_sounds(false)).any?
        subs = disabled.map { |p| "name=!#{p.nick}" }
        selector = merge_selectors(selector, "@#{selector[1]}[#{subs.join(',')}]")
      end
    
      result = execute("execute #{selector} ~ ~ ~ playsound #{sound} @p ~0 ~0 ~0 #{options[:volume]} #{options[:pitch]}") unless selector.nil?
    
      unless result.nil?
        result.split('Played sound ').reject(&:empty?).join(', ').
          split('That player cannot be found').reject(&:empty?).join(', ')
      end
    end
  end
end
