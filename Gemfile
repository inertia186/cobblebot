source 'https://rubygems.org'

ruby '3.3.12'

# CobbleBot's export/import tasks use CSV, which is no longer a default gem in
# Ruby 3.4.
gem 'csv', '~> 3.2'

# Run the supported Rails 8.1 framework and configuration-defaults lane.
gem 'rails', '~> 8.1.3'

# Keep JSON explicit for application APIs and export/import tasks.
gem 'json', '>= 2.6'

# Use sqlite3 as the database for Active Record
# sqlite3 2.9 supplies current native packages for the supported Ruby 3.3 lane.
gem 'sqlite3', '~> 2.9', require: false, platforms: :ruby

# Use PostgreSQL for concurrent deployments and the complete CI suite.
gem 'pg', '~> 1.5', platforms: :ruby

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.2'

# Highlight callback Ruby locally; watchdog maintenance must not depend on the
# retired external Pygments service.
gem 'rouge', '~> 5.1'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby, require: false

# Mainly to cache images.
gem 'actionpack-action_caching', '~> 1.1'

# jQuery and UJS are vendored with the other preserved frontend assets.

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Responders 3 supplies the maintained Rails integration.
gem 'responders', '~> 3.1'

# CobbleBot uses java_properties to read Minecraft server properties.
gem 'java_properties', '~> 0.0.4'

# CobbleBot uses minecraft-query to do basic queries on a Minecraft Server.
gem 'minecraft-query', '~> 1.0'

# CobbleBot uses file-tail to read latest.log of the Minecraft Server.
gem 'file-tail', '~> 1.4'

# CobbleBot uses mechanize to get the HTML title when displaying a link.
gem 'mechanize', '~> 2.9'
# Mechanize's HTTP test boundary requires WEBrick explicitly on modern Ruby.
gem 'webrick', '~> 1.8'

# Adds machine learning capabilities directly to models.
# gem 'cabalist'

# Adds general machine learning capabilities.
gem 'ai4r', '~> 2.0'

# CobbleBot uses redis/resque to kick off the log monitor and other stuff.
gem 'redis', '~> 6.0', require: false
# CobbleBot constructs Redis::Namespace directly in its configuration service.
gem 'redis-namespace', '~> 1.11', require: false
gem 'resque', '~> 3.0', require: 'resque/server'
gem 'resque-scheduler', '~> 5.0', require: false
# Resque Server runs on Sinatra; keep its verified Rack-major shelf explicit.
gem 'sinatra', '~> 4.2', require: false

# IRC
# Bound IRC command execution without creating one native thread per message.
gem 'concurrent-ruby', '~> 1.3'
gem 'summer', '~> 1.0'

# Use this if there are problems with the latest version.
#gem 'rufus-scheduler', '~> 2.0.24'

# Haml 7 uses the supported Ruby 3.3/Prism rendering lane.
gem 'haml', '~> 7.3'

# Paginate admin result indexes.
gem 'will_paginate', '~> 4.0'

# For 'Calc' callback
gem 'dentaku', '~> 4.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1'

# Puma serves the Rails web process in production and Capybara in tests.
gem 'puma', '~> 8.0'

# Use Unicorn as an alternative app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Assets

# Rails 7 no longer includes Sprockets through the Rails meta-gem.
gem 'sprockets-rails', '~> 3.5'

# Bootstrap, AngularJS, jQuery, and their legacy UI dependencies are vendored
# under vendor/assets so production does not depend on Sass or rails-assets.org.

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
#  gem 'spring'

  gem 'better_errors', '~> 2.1', require: false, platforms: :ruby
end

group :test do
  gem 'minitest', '~> 6.0'
  gem 'minitest-mock', '~> 5.27'
  gem 'capybara', '~> 3.40'
  gem 'capybara-screenshot', '~> 1.0'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'selenium-webdriver', '~> 4.46'
  gem 'simplecov', '~> 1.0', require: false
  gem 'webmock', '~> 3.25', require: false
  gem 'rexml', '~> 3.4', require: false
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 13.0', platforms: :ruby

  # For quick dumps: https://github.com/yamldb/yaml_db
  #gem 'yaml_db'
end
