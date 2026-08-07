source 'https://rubygems.org'

ruby '3.3.12'

# CobbleBot's export/import tasks use CSV, which is no longer a default gem in
# Ruby 3.4.
gem 'csv', '~> 3.2'

# TEMP Ruby 3 spike cut: let a modern Bundler drive resolution so we can expose the next real blocker.
# gem 'bundler', '>= 1.12'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
# Use the production-verified Rails 7.2 framework and defaults baseline.
gem 'rails', '~> 7.2.3.2'

# TEMP Ruby 3 / Rails 6.1 spike cut: old json 1.8.5 is not viable on this stack.
gem 'json', '>= 2.6'

# Use sqlite3 as the database for Active Record
# TEMP Ruby 3 spike cut: old sqlite3 1.3.x does not build on Ruby 3.
gem 'sqlite3', '~> 1.6', '>= 1.6.9', require: false, platforms: :ruby

# Use postgresql if you're tired of SQLite errors.
# TEMP Ruby 3 spike cut: old pg 1.0.x still calls removed taint APIs on Ruby 3.
gem 'pg', '~> 1.5', platforms: :ruby

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.2'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 5.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby, require: false

# Mainly to cache images.
gem 'actionpack-action_caching', '~> 1.1'

# Use jquery as the JavaScript library
# TEMP vendor cut: vendored jquery2.js and jquery_ujs.js now satisfy the asset side.
# gem 'jquery-rails', '~> 4.1'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# TEMP Ruby 3 / Rails 6.1 spike cut: responders 2.x tops out below this Rails shelf.
gem 'responders', '~> 3.1'

# bundle exec rake doc:rails generates the API under doc/api.
# TEMP Ruby 3 / Rails 6.1 spike cut: sdoc pins json below a viable modern version.
# gem 'sdoc', '~> 0.4', group: :doc

# CobbleBot uses java_properties to read the Mineraft Server server.properites.
gem 'java_properties', '~> 0.0.4'

# CobbleBot uses minecraft-query to do basic queries on a Minecraft Server.
gem 'minecraft-query', '~> 1.0'

# CobbleBot uses file-tail to read latest.log of the Minecraft Server.
gem 'file-tail', '~> 1.4'

# CobbleBot uses mechanize to get the HTML Title when displaying a link to players.
# TEMP Ruby 3 spike cut: old mechanize/mime-types stack is not Ruby-3-clean.
gem 'mechanize', '~> 2.9'
# TEMP Ruby 3 spike cut: WEBrick is no longer bundled with Ruby stdlib.
gem 'webrick', '~> 1.8'

# Adds machine learning capabilities directly to models.
# gem 'cabalist'

# Adds general machine learning capabilities.
gem 'ai4r', '~> 2.0'

# CobbleBot uses redis/resque to kick off the log monitor and other stuff.
gem 'redis', '~> 5.4', '>= 5.4.1', require: false
# CobbleBot constructs Redis::Namespace directly in its configuration service.
gem 'redis-namespace', '~> 1.11', require: false
gem 'resque', '~> 3.0', require: 'resque/server'
gem 'resque-scheduler', '~> 5.0', require: false
# Resque Server runs on Sinatra; keep its verified Rack-major shelf explicit.
gem 'sinatra', '~> 4.2', require: false

# IRC
gem 'summer', '~> 1.0'

# Use this if there are problems with the latest version.
#gem 'rufus-scheduler', '~> 2.0.24'

# TEMP Ruby 3 / Rails 5.2 spike cut: Haml 4 expects old Erubis handler APIs.
gem 'haml', '~> 5.2'

# Paginate admin result indexes.
gem 'will_paginate', '~> 4.0'

# For 'Calc' callback
gem 'dentaku', '~> 4.0'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Assets

# Rails 7 no longer includes Sprockets through the Rails meta-gem.
gem 'sprockets-rails', '~> 3.5'

# Bootstrap 4 ruby gem for Ruby on Rails (Sprockets) and Compass.
# TEMP spike cut: disabled alongside Sass to avoid the old asset/ffi branch.
# gem 'bootstrap', '~> 4.0'
# gem 'bootstrap-glyphicons'
# Wraps the Angular.js UI Bootstrap library.
# TEMP vendor cut: vendored JS/CSS now satisfies the asset side.
# gem 'angular-ui-bootstrap-rails', '~> 1.3'

# TEMP vendor cut: vendored JS/CSS now satisfies the asset side.
# source 'https://rails-assets.org' do
#   gem 'rails-assets-angular', '~> 1.5'
#   gem 'rails-assets-angular-inview', '~> 1.5'
#   gem 'rails-assets-angular-animate', '~> 1.5'
#   gem 'rails-assets-angular-resource', '~> 1.5'
#   gem 'rails-assets-angular-flash-alert', '~> 1.1'
#   gem 'rails-assets-angular-cancel-on-navigate', '~> 0.1'
#   gem 'rails-assets-ngclipboard', '~> 1.0'
#   gem 'rails-assets-clipboard', '~> 1.5'
#   gem 'rails-assets-nprogress', '~> 0.2'
#   gem 'rails-assets-moment', '~> 2.13'
#   gem 'rails-assets-chosen', '~> 1.5'
#   # Tooltips and popovers depend on tether for positioning.
#   gem 'rails-assets-tether', '>= 1.3'
# end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  # TEMP Ruby 3 / Rails 5.2 spike cut: old web-console stack is not worth saving here.
  # gem 'web-console', '~> 2.2', platforms: :ruby

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
#  gem 'spring'

  gem 'better_errors', '~> 2.1', require: false, platforms: :ruby
  # TEMP Ruby 3 / Rails 5.2 spike cut: old binding_of_caller native extension is not worth saving here.
  # gem 'binding_of_caller', '~> 0.7', require: false, platforms: :ruby
  gem 'rack-mini-profiler', '~> 0.10', require: false
end

group :test do
  gem 'minitest', '~> 5.25'
  gem 'capybara', '~> 3.40'
  gem 'capybara-screenshot', '~> 1.0'
  gem 'puma', '~> 6.4'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'selenium-webdriver', '~> 4.40'
  gem 'simplecov', '~> 0.22', require: false
  gem 'webmock', '~> 3.25', require: false
  gem 'rexml', '~> 3.4', require: false
  # TEMP Ruby 3 / Rails 6.1 spike cut: memory_test_fix does not support this Rails shelf.
  # gem 'memory_test_fix', '~> 1.3'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # TEMP Ruby 3 spike cut: old byebug 9.x native extension does not build on Ruby 3.2.
  gem 'byebug', '~> 11.1', platforms: :ruby

  # TEMP Ruby 3 / Rails 5.2 spike cut: old pry/pry-rails stack is not worth saving here.
  # gem 'pry-rails', '~> 0.3'
  # For quick dumps: https://github.com/yamldb/yaml_db
  #gem 'yaml_db'
end
