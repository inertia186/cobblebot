class Link < ActiveRecord::Base
  attr_accessor :skip_populate_from_response
  
  belongs_to :actor, polymorphic: true

  scope :optionally_for_url, lambda { |url = nil|
    if !!url
      where(url: url)
    else
      all
    end
  }
  scope :expired, lambda { |expired = true, url = nil|
    if expired
      optionally_for_url(url).where('expires_at IS NULL OR expires_at < ?', Time.now)
    else
      optionally_for_url(url).where('expires_at IS NOT NULL AND expires_at > ?', Time.now)
    end
  }
  scope :query, lambda { |query|
    clause = <<-DONE
      links.url LIKE ? OR
      links.title LIKE ?
    DONE
    where(clause, query, query)
  }
  
  after_initialize :populate_from_response
  
  def self.find_or_create_by_url(url)
    find_or_create_by(url: url)
  end

  def to_param
    "#{id}-#{url.parameterize}"
  end
    
  def populate_from_response(refresh_persisted = false)
    return if !!skip_populate_from_response
    return unless !!url
    return if !new_record? && expired? && !refresh_persisted

    if new_record?
      agent = populate_from_get_response(url, self)
    
      return unless agent.page
    elsif expired?
      agent = Mechanize.new
      agent.keep_alive = false
      agent.open_timeout = 5
      agent.read_timeout = 5
      agent.head url

      if agent.page.nil?
        agent = populate_from_get_response(self.url, self)
      elsif !!( timestamp = agent.page.response['last-modified'] ) && Time.parse(timestamp) != last_modified_at
        agent = populate_from_get_response(self.url, self)
      end
    end

    original_title = self.title
    self.url = url
    self.title = title.gsub(/[^a-zA-Z0-9:?&=#@+*, \.\/\"\[\]\(\)]/, '-').truncate(90) unless title.nil?

    if agent
      self.expires_at = extract_expires_at(agent.page.response)
      self.last_modified_at = agent.page.response['last-modified'] || Time.now
    end
    
    Rails.logger.warn "Removed characters from: #{original_title}" if title != original_title # FIXME Remove later.
    
    self
  end

  def expired?
    expires_at.present? && expires_at < Time.now
  end
  
  def embedded_url
    if url =~ /youtube/
      id = url.split("v=").last.split("&").first
      "http://www.youtube.com/embed/#{id}?rel=0&border=&autoplay=1"
    elsif url =~ /youtu.be/
      id = url.split('/').last
      "http://www.youtube.com/embed/#{id}?rel=0&border=&autoplay=1"      
    else
      url
    end
  end
  
  def can_embed?
    return can_embed unless can_embed.nil?
    
    agent = Mechanize.new
    agent.keep_alive = false
    agent.open_timeout = 5
    agent.read_timeout = 5
    agent.get embedded_url
    
    can_embed = agent.page.response['x-frame-options'] != 'deny'
    update_attribute(:can_embed, can_embed) # no AR callbacks
    
    can_embed
  rescue Mechanize::ResponseCodeError => e
    update_attribute(:can_embed, false) # no AR callbacks
  end
private
  def populate_from_get_response(url, link)
    begin
      agent = Mechanize.new
      agent.keep_alive = false
      agent.open_timeout = 5
      agent.read_timeout = 5
      agent.head url

      link.title = if agent.page && defined?(agent.page.title) && agent.page.title
        agent.page.title.strip
      else
        url
      end
    rescue SocketError => e
      Rails.logger.warn "Ignoring url: #{link.url}" && return
    rescue Net::OpenTimeout => e
      link.title = url
    rescue Net::HTTP::Persistent::Error => e
      link.title = url
    rescue StandardError => e
      link.title = e.inspect
    end

    agent
  end

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