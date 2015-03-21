class Link < ActiveRecord::Base
  belongs_to :actor, polymorphic: true

  scope :optionally_for_url, lambda { |url = nil|
    if !!url
      where(url: url)
    else
      all
    end
  }
  scope :unexpired, lambda { |url = nil| optionally_for_url(url).where('expires_at > ?', Time.now) }
  scope :expired, lambda { |url = nil| optionally_for_url(url).where('expires_at < ?', Time.now) }
  
  after_initialize :populate_from_response
  
  def populate_from_response
    return unless new_record?
    return unless !!url
    
    begin
      agent = Mechanize.new
      agent.keep_alive = false
      agent.open_timeout = 5
      agent.read_timeout = 5
      agent.get url

      title = if agent.page && defined?(agent.page.title) && agent.page.title
        agent.page.title.strip
      else
        url
      end
    rescue SocketError => e
      Rails.logger.warn "Ignoring url: #{url}" && return
    rescue Net::OpenTimeout => e
      title = url
    rescue Net::HTTP::Persistent::Error => e
      title = url
    rescue StandardError => e
      title = e.inspect
    end

    original_title = title
    self.url = url
    self.title = title.gsub(/[^a-zA-Z0-9:?&=#@+*, \.\/\"\[\]\(\)]/, '-').truncate(90)
    
    return unless agent.page

    self.expires_at = extract_expires_at(agent.page.response)
    self.last_modified_at = agent.page.response['last-modified'] || Time.now
    Rails.logger.warn "Removed characters from: #{original_title}" if title != original_title # FIXME Remove later.
  end
private
  def extract_expires_at(response)
    response_date = if !!response['date']
      Time.parse(response['date'])
    else
      Time.now
    end
    
    if !!(cache_control = response['cache-control'])
      return response_date + 3600.seconds if cache_control == 'no-cache'
      return response_date + cache_control.split('=').last.to_i
    elsif !!(expires = response['Expires'])
      return Time.parse(expires)
    else
      return response_date + 3600.seconds
    end
  rescue StandardError => e
    Rails.logger.warn "Unable to extract expires at from response #{response.inspect}, because: #{e.inspect}"
  end
end