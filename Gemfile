source 'https://rubygems.org'

gem 'bundler', '>= 1.12'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.10'

# Needed by activesupport
gem 'json'

# Rescue an error and then re-raise your own nested exceptions.
gem 'nesty'

# Use sqlite3 as the database for Active Record
gem 'sqlite3', require: false, platforms: :ruby

# Use postgresql if you're tired of SQLite errors.
gem 'pg', platforms: :ruby
# gem 'pg', platforms: :jruby, git: 'git://github.com/headius/jruby-pg.git', :branch => :master

# Enables sqlite3 on jruby
gem 'jruby-openssl', platform: :jruby
gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 3.0'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby, require: false

# Mainly to cache images.
gem 'actionpack-action_caching', '~> 1.1'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.1'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
gem 'responders', '~> 2.2'

# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', group: :doc#, '~> 0.4'

# CobbleBot uses java_properties to read the Mineraft Server server.properites.
gem 'java_properties', '~> 0.0.4'

# CobbleBot uses minecraft-query to do basic queries on a Minecraft Server.
gem 'minecraft-query', '~> 1.0'

# CobbleBot uses file-tail to read latest.log of the Minecraft Server.
gem 'file-tail', '~> 1.1.1'

# CobbleBot uses mechanize to get the HTML Title when displaying a link to players.
gem 'mechanize', '~> 2.7'

# CobbleBot uses slack-api to communicate with slack.com for servers that would like such integration.  Get an API token here: http://slack.com/
gem 'slack-api', '~> 1.2'

# CobbleBot uses beeline-rb to communicate with beechat.hive-engine.com
gem 'beeline-rb', path: '../beeline-rb', require: 'beeline'#, '~> 0.0'

# Can be used by callbacks.
gem 'mc-slap', git: 'git://gist.github.com/5002463.git'
# Used to translate in-game chat.
gem 'google-translate', '~> 1.1'

# Adds machine learning capabilities directly to models.
# gem 'cabalist'

# Adds general machine learning capabilities.
gem 'ai4r', '~> 1.13'

# CobbleBot uses redis/resque to kick off the log monitor and other stuff.
gem 'redis', '~> 3.3', require: false
gem 'redis-store', '~> 1.1', require: false
gem 'resque', '~> 1.26', require: 'resque/server'
gem 'resque-scheduler', '~> 4.2', require: false

# IRC
gem 'summer', '~> 1.0'

# Use this if there are problems with the latest version.
#gem 'rufus-scheduler', '~> 2.0.24'

gem 'haml', '~> 4.0'

gem 'will_paginate', '~> 3.1'

# For 'Calc' callback
gem 'dentaku', '~> 2.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Assets

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', github: 'rails/turbolinks', branch: 'master'
# Bootstrap 4 ruby gem for Ruby on Rails (Sprockets) and Compass.
gem 'bootstrap', '~> 4.0'
gem 'bootstrap-glyphicons'
# Wraps the Angular.js UI Bootstrap library.
gem 'angular-ui-bootstrap-rails', '~> 1.3'

source 'https://rails-assets.org' do
  gem 'rails-assets-angular', '~> 1.5'
  gem 'rails-assets-angular-inview', '~> 1.5'
  gem 'rails-assets-angular-animate', '~> 1.5'
  gem 'rails-assets-angular-resource', '~> 1.5'
  gem 'rails-assets-angular-flash-alert', '~> 1.1'
  gem 'rails-assets-angular-cancel-on-navigate', '~> 0.1'
  gem 'rails-assets-ngclipboard', '~> 1.0'
  gem 'rails-assets-clipboard', '~> 1.5'
  gem 'rails-assets-nprogress', '~> 0.2'
  gem 'rails-assets-moment', '~> 2.13'
  gem 'rails-assets-chosen', '~> 1.5'
  # Tooltips and popovers depend on tether for positioning.
  gem 'rails-assets-tether', '>= 1.3'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.2', platforms: :ruby

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
#  gem 'spring'

  gem 'better_errors', '~> 2.1', require: false, platforms: :ruby
  gem 'binding_of_caller', '~> 0.7', require: false, platforms: :ruby
  gem 'rack-mini-profiler', '~> 0.10', require: false
end

group :test do
  gem 'capybara', '~> 2.18'
  gem 'capybara-angular', '~> 0.2'
  gem 'capybara-screenshot', '~> 1.0'
  gem 'poltergeist', '~> 1.9'
  gem 'phantomjs', '~> 2.1', require: 'phantomjs/poltergeist'
  gem 'simplecov', '~> 0.11', require: false
  gem 'simplecov-csv', '~> 0.1', require: false
  gem 'webmock', '~> 2.0', require: false
  gem 'database_cleaner', '~> 1.5', require: false
  gem 'memory_test_fix', '~> 1.3'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 9.0', platforms: :ruby

  gem 'pry-rails', '~> 0.3'
  gem 'malp', github: 'inertia186/malp'#, ref: 'b0d172c'
  # For quick dumps: https://github.com/yamldb/yaml_db
  #gem 'yaml_db'
end

