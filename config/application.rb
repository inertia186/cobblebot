require File.expand_path('../boot', __FILE__)

# TEMP Ruby 3 / Rails 6.1 spike cut: ensure stdlib Logger is loaded before ActiveSupport touches it.
require 'logger'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Cobblebot
  class Application < Rails::Application
    # TEMP Ruby 3 / Rails 6.1 spike cut: keep legacy constant loading semantics while the app is still pre-Zeitwerk.
    config.autoloader = :classic

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # TEMP Ruby 3 / modern Rails spike: this old Rails 4 callback setting is obsolete on newer Rails.
    config.middleware.use Rack::Deflater
  end
end
