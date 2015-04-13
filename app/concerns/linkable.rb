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
          link.actor = Player.find_by_nick(options[:nick]) if !!options[:nick]
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
          "text": "#{title}", "color": "dark_purple", "underlined": "true", "hoverEvent": {
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
      q = URI.encode_www_form([ ["q", query] ])
      generate_lmgtfy_url = "http://lmgtfy.com/?#{q}"
      base_url = "http://is.gd/create.php?format=json&url="
      is_gd_request_url = URI.parse(base_url + generate_lmgtfy_url)
      url = JSON.parse(Net::HTTP.get_response(is_gd_request_url).body).fetch("shorturl")
    
      return if selector.nil?
    
      say_link selector, url, title: query, only_title: true
    end
  end
end
