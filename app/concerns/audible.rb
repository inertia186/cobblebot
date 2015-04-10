module Audible
  extend ActiveSupport::Concern
  extend Commandable
  
  module ClassMethods
    def play_sound(selector, sound, options = {volume: '', pitch: ''})
      selector = prep_play_sound_selector(selector)    
      clean_play_sound_result execute("execute #{selector} ~ ~ ~ playsound #{sound} @p ~0 ~0 ~0 #{options[:volume]} #{options[:pitch]}") unless selector.nil?
    end
  private
    def prep_play_sound_selector(selector)
      if (disabled = Server.players.play_sounds(false)).any?
        subs = disabled.map { |p| "name=!#{p.nick}" }
        selector = merge_selectors(selector, "@#{selector[1]}[#{subs.join(',')}]")
      end
      
      selector
    end
  
    def clean_play_sound_result(result)
      unless result.nil?
        result.split('Played sound ').reject(&:empty?).join(', ').
          split('That player cannot be found').reject(&:empty?).join(', ')
      end
    end
  end
end
