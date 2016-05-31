source 'https://rubygems.org'

gem 'bundler', '>= 1.12.5'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'

# Use sqlite3 as the database for Active Record
gem 'sqlite3', require: false, platforms: :ruby

# Use postgresql if you're tired of SQLite errors.
gem 'pg', platforms: :ruby
# gem 'pg', platforms: :jruby, git: 'git://github.com/headius/jruby-pg.git', :branch => :master

# Enables sqlite3 on jruby
gem 'jruby-openssl', platform: :jruby
gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0.4'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 3.0.0'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.1'

# A great Javascript framework.
gem 'angularjs-rails', '~> 1.5.6'

# Parse, validate, manipulate, and display dates in JavaScript.
gem 'momentjs-rails', '~> 2.11.1'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby, require: false

# Used to make HMTL select tags nicer.
gem 'chosen-rails', '~> 1.5.2'

# Required by chosen-rails
gem 'sprockets', '~> 3.6.0'
gem 'compass-rails', '~> 3.0.2'

# Mainly to cache images.
gem 'actionpack-action_caching', '~> 1.1.1'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.1.1'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', github: 'rails/turbolinks', branch: 'master'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5.0'
gem 'responders', '~> 2.2.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# CobbleBot uses java_properties to read the Mineraft Server server.properites.
gem 'java_properties', '~> 0.0.4'

# CobbleBot uses minecraft-query to do basic queries on a Minecraft Server.
gem 'minecraft-query', '~> 1.0.0'

# CobbleBot uses file-tail to read latest.log of the Minecraft Server.
gem 'file-tail', '~> 1.1.1'

# CobbleBot uses mechanize to get the HTML Title when displaying a link to players.
gem 'mechanize', '~> 2.7.4'

# CobbleBot uses slack-api to communicate with slack.com for servers that would like such integration.  Get an API token here: http://slack.com/
gem 'slack-api', '~> 1.2.3'

# Can be used by callbacks.
gem 'mc-slap', git: 'git://gist.github.com/5002463.git'
# Used to translate in-game chat.
gem 'google-translate', '~> 1.1.2'

# Adds machine learning capabilities directly to models.
# gem 'cabalist'

# Adds general machine learning capabilities.
gem 'ai4r', '~> 1.13'

# CobbleBot uses redis/resque to kick off the log monitor and other stuff.
gem 'redis', '~> 3.3.0', require: false
gem 'redis-store', '~> 1.1.7', require: false
gem 'resque', '~> 1.26.0', require: 'resque/server'
gem 'resque-scheduler', '~> 4.2.0', require: false

# IRC
gem 'summer', '~> 1.0.1'

# Use this if there are problems with the latest version.
#gem 'rufus-scheduler', '~> 2.0.24'

gem 'haml', '~> 4.0.7'

gem 'will_paginate', '~> 3.1.0'

# For 'Calc' callback
gem 'dentaku', '~> 2.0.8'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.2.1', platforms: :ruby

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
#  gem 'spring'

  gem 'better_errors', '~> 2.1.1', require: false, platforms: :ruby
  gem 'binding_of_caller', '~> 0.7.2', require: false, platforms: :ruby
  gem 'rack-mini-profiler', '~> 0.10.1', require: false
end

group :test do
  gem 'capybara', '~> 2.7.1'
  gem 'capybara-angular', '~> 0.2.3'
  gem 'capybara-screenshot', '~> 1.0.13'
  gem 'poltergeist', '~> 1.9.0'
  gem 'phantomjs', '~> 2.1.1.0', require: 'phantomjs/poltergeist'
  gem 'simplecov', '~> 0.11.2', require: false
  gem 'simplecov-csv', '~> 0.1.3', require: false
  gem 'webmock', '~> 2.0.3', require: false
  gem 'codeclimate-test-reporter', '~> 0.5.0'
  gem 'database_cleaner', '~> 1.5.3', require: false
  gem 'memory_test_fix', '~> 1.3.0'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 9.0.5', platforms: :ruby

  gem 'pry-rails', '~> 0.3.4'
  gem 'malp', github: 'inertia186/malp'#, ref: 'b0d172c'
  # For quick dumps: https://github.com/yamldb/yaml_db
  #gem 'yaml_db'
end

