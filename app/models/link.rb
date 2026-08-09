class Link < ActiveRecord::Base
  attr_accessor :skip_populate_from_response
  
  belongs_to :actor, polymorphic: true, optional: true

  validate :url_must_be_public, if: -> { url.present? && (new_record? || will_save_change_to_url?) }

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
      page = agent&.page

      return unless page
    elsif expired?
      agent = CobbleBotAgent.new
      page = agent.head url

      if page.nil? || page.title.nil?
        agent = populate_from_get_response(self.url, self)
        page = agent&.page
      elsif !!( timestamp = page.response['last-modified'] ) && Time.parse(timestamp) != last_modified_at
        agent = populate_from_get_response(self.url, self)
        page = agent&.page
      end
    end

    original_title = self.title
    self.url = url
    self.title = title.gsub(/[^a-zA-Z0-9:?&=#@+*, \.\/\"\[\]\(\)]/, '-').truncate(90) unless title.nil?

    if page
      self.expires_at = extract_expires_at(page.response)
      self.last_modified_at = page.response['last-modified'] || Time.now
    end
    
    Rails.logger.warn "Removed characters from: #{original_title}" if title != original_title # FIXME Remove later.
    
    save if changed? && !new_record?
    
    self
  end

  def expired?
    expires_at.nil? || expires_at < Time.now
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
    persisted_can_embed = self[:can_embed]
    return persisted_can_embed unless persisted_can_embed.nil?
    
    agent = CobbleBotAgent.new
    page = agent.head embedded_url
    
    return unless !!page.response
    
    fetched_can_embed = response_embeddable?(page.response)
    update_attribute(:can_embed, fetched_can_embed) # no AR callbacks

    fetched_can_embed
  rescue Mechanize::ResponseCodeError
    update_attribute(:can_embed, false) # no AR callbacks
    false
  rescue Errno::ENETUNREACH
    # try again later
  end
private
  def populate_from_get_response(url, link)
    begin
      agent = CobbleBotAgent.new
      agent.get url
      page = agent.page

      return unless !!page.response

      link.can_embed = response_embeddable?(page.response)

      link.title = if page && defined?(page.title) && page.title
        page.title.strip
      else
        url
      end
    rescue SocketError => e
      link.title ||= url
      Rails.logger.warn "Ignoring url: #{link.url}"
      return
    rescue Net::OpenTimeout => e
      link.title = url
    rescue Net::HTTP::Persistent::Error => e
      link.title = url
    rescue StandardError => e
      link.title = e.inspect
    end

    agent
  end

  def url_must_be_public
    CobbleBotAgent.validate_url!(url)
  rescue CobbleBotAgent::UnsafeUrlError => e
    errors.add(:url, e.message)
  end

  def response_embeddable?(response)
    policies = response['x-frame-options'].to_s.split(',').map do |policy|
      policy.strip.downcase
    end

    policies.none? { |policy| %w[deny sameorigin].include?(policy) }
  end

  def extract_expires_at(response)
    response_date = if !!response['date']
      Time.parse(response['date'])
    else
      Time.now
    end
    
    if !!(cache_control = response['cache-control'])
      directives = cache_control.split(',').map { |directive| directive.strip.downcase }
      return response_date if directives.any? { |directive| %w[no-cache no-store].include?(directive) }

      max_age = directives.filter_map do |directive|
        match = directive.match(/\Amax-age\s*=\s*"?(\d+)"?\z/)
        Integer(match[1], 10) if match
      end.first
      return response_date + max_age if max_age

      return response_date
    elsif !!(expires = response['Expires'])
      return Time.parse(expires)
    else
      return response_date + 3600.seconds
    end
  rescue StandardError => e
    Rails.logger.warn "Unable to extract expires at from response #{response.inspect}, because: #{e.inspect}"
  end
end
