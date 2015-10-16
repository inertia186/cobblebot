source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.4'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', require: false
# Use postgresql if you're tired of SQLite errors.
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby, require: false
# Used to make HMTL select tags nicer.
gem 'chosen-rails'
# Required by chosen-rails
gem 'sprockets', '2.12.3'
gem 'compass-rails', '~> 2.0.4'

# Mainly to cache images.
gem 'actionpack-action_caching'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
gem 'responders', '~> 2.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# CobbleBot uses java_properties to read the Mineraft Server server.properites.
gem 'java_properties'

# CobbleBot uses minecraft-query to do basic queries on a Minecraft Server.
gem 'minecraft-query'

# CobbleBot uses file-tail to read latest.log of the Minecraft Server.
gem 'file-tail'

# CobbleBot uses mechanize to get the HTML Title when displaying a link to players.
gem 'mechanize'

# Can be used by callbacks.
gem 'mc-slap', git: 'git://gist.github.com/5002463.git'
# Used to translate in-game chat.
gem 'google-translate'

# CobbleBot uses redis/resque to kick off the log monitor and other stuff.
gem 'redis', require: false
gem 'redis-store', require: false
gem "resque", require: 'resque/server'
gem 'resque-scheduler', require: false

# IRC
gem 'summer'

# Use this if there are problems with the latest version.
#gem 'rufus-scheduler', '~> 2.0.24'

gem 'haml'

gem 'will_paginate'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
#  gem 'spring'

  gem 'better_errors', require: false
  gem 'binding_of_caller', require: false
  gem 'rack-mini-profiler', require: false
end

group :test do
  gem 'simplecov', require: false
  gem 'simplecov-csv', require: false
  gem 'webmock', require: false
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner', require: false
  gem 'memory_test_fix'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem 'pry-rails'
  gem 'malp', github: 'inertia186/malp', require: false
end
