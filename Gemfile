source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.2'

# Use sqlite3 as the database for Active Record
group :development do
  gem 'sqlite3', '1.3.8'
end
group :production do
  gem 'pg'
end

gem 'marky_markov'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
#gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# to fix jquery events with turbolinks
gem 'jquery-turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# bootstrap
gem 'bootstrap-sass', '~> 3.1.0'

# figaro for setting configs through application.yml and ENV variables
gem 'figaro', '~> 0.7.0'

group :production do
  # exception notification for email exceptions
  gem 'exception_notification', '~> 4.0.1'

  # fcgi for fcgi script running
  gem 'passenger', '~> 4.0.23'
end

gem 'twitter'

gem 'haml-rails'

gem 'sidekiq'
gem 'sinatra', require: false
gem 'slim'
gem 'sidekiq-status'

gem 'openlayers-rails'
gem 'geocoder'
