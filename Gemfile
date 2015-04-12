source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', require: false
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0', require: false
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0', require: false
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0', require: false
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby, require: false

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0', require: false
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
gem 'mc-slap', gist: '5002463'

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
end

group :test do
  gem 'simplecov', require: false
  gem 'simplecov-csv', require: false
  gem 'webmock', require: false
  gem 'codeclimate-test-reporter'
  gem 'database_cleaner', require: false
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem 'pry-rails'
  gem 'malp', github: 'inertia186/malp', require: false
end
