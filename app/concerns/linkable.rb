module Linkable
  extend Commandable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    ## Renders a hyperlink.
    def say_link(selector, url, options = {})
      text = url.gsub(/http/i, 'http')
      url = text.split('http')[1]
      return unless url

      player = Player.find_by_nick(options[:nick]) if !!options[:nick]
      return if !!player && !player.may_autolink?

      url = "http#{url.split(' ')[0]}"
      return unless !!url.split('://')[1]
    
      if !!options[:title]
        url = url
        title = if !!options[:only_title]
          options[:title]
        else
          "#{url.split('/')[2]} :: #{title.strip}"
        end
        last_modified_at = Time.now
      else
        links = Link.expired(false, url)

        if links.any?
          link = links.last
        else
          link = Link.find_or_create_by_url(url)
          link.actor = player
          link.save
        end
    
        url = link.url
        title = if link.title
          if !!options[:only_title]
            link.title.strip
          else
            "#{link.url.split('/')[2]} :: #{link.title.strip}"
          end
        else
          link.url
        end
        last_modified_at = link.last_modified_at
      end
    
      execute(<<-DONE
        tellraw #{selector} { "text": "", "extra": [{
          "text": "#{escape(title)}", "color": "dark_purple", "underlined": "true", "hoverEvent": {
            "action": "show_text", "value": "Last Modified: #{last_modified_at ? last_modified_at : '???'}"
          }, "clickEvent": {
            "action": "open_url", "value": "#{url}"
          }
        }]}
      DONE
      ) unless selector.nil?
    
      if !!link
        link
      else
        [url, title, last_modified_at]
      end
    end
  
    def say_lmgtfy_link(selector, query)
      return if selector.nil?

      q = URI.encode_www_form([ ["q", query] ])
      lmgtfy_url = "http://lmgtfy.com/?#{q}"
    
      say_link selector, lmgtfy_url, title: query, only_title: true
    end
  end
end
