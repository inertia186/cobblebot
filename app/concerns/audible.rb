module Audible
  extend Commandable
  extend Runnable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def play_sound(selector, sound, options = {volume: '', pitch: ''})
      selector = prep_play_sound_selector(selector)    
      clean_play_sound_result execute("execute #{selector} ~ ~ ~ playsound #{sound} @p ~0 ~0 ~0 #{options[:volume]} #{options[:pitch]}") unless selector.nil?
    end
    
    def check_mail(nick)
      player = Player.find_by_nick nick
      return if player.nil?

      run do
        # Slight delay here to make sure resource packs have loaded.
        sleep(5)
      
        if (messages = player.messages.read(false).deleted(false).muted(false)).any?
          execute <<-DONE
            tellraw #{nick} {"color": "green", "text": "You have ", "extra": [
              {"text": "#{pluralize(messages.count, 'unread message')}", "color": "dark_purple", "underlined": "true", "clickEvent": {
                "action": "run_command", "value": "@server mail"}, "hoverEvent":  {"action": "show_text", "value": "Type: @server mail"
              }}
            ]}
          DONE
        
          play_sound(nick, 'mailsound')
        end
      end
    end
  private
    def prep_play_sound_selector(selector)
      return nil if Server.players.none?
      
      if (disabled = Server.players.play_sounds(false)).any?
        subs = disabled.map { |p| "name=!#{p.nick}" }
        selector = merge_selectors(selector, "@#{selector[1]}[#{subs.join(',')}]")
      end
      
      selector
    end
  
    def clean_play_sound_result(result)
      return unless result
      
      unless result.nil?
        [
          'Played sound ',
          'That player cannot be found',
          /Player [^ ]* is too far away to hear the sound/
        ].each do |junk|
          if result.respond_to?(:split)
            result = result.split(junk).reject(&:empty?).join(', ')
          end
        end
        
        result
      end
    end
  end
end
