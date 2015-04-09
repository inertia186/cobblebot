# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

COBBLEBOT_VERSION = '0.0.1'

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  if html_tag =~ /<(label)/
    html_field = Nokogiri::HTML::DocumentFragment.parse(html_tag)
    html_field.children.add_class 'alert-danger'
    html_field.to_s.html_safe
  else
    html_tag
  end
end

unless Rails.env == 'test'
  if Resque.size("minecraft_watchdog") == 0
    Rails.logger.info "Equeuing minecraft_watchdog.  Current queue: #{Resque.size('minecraft_watchdog')}"
    Resque.enqueue(MinecraftWatchdog)
  end
end
