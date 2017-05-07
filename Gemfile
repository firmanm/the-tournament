source 'https://rubygems.org'
ruby '2.3.1'

gem 'rails', '5.0.0'
# gem 'rails', '4.2.6'
gem 'pg'
gem 'foreman', '0.71.0'
gem 'unicorn'
gem 'newrelic_rpm'

gem 'sass-rails'
gem 'haml-rails'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jquery-turbolinks'
gem 'jbuilder', '~> 1.2'
gem 'kaminari'
gem 'gon'
gem 'acts-as-taggable-on'
gem 'countries', :require => 'countries/global'
gem 'meta-tags', require: 'meta_tags'
gem 'zip'
gem 'simple-rss'
gem 'sitemap_generator'
gem 'carrierwave'
gem 'fog'
gem 'addressable'
gem 'data_uri'


#Bootstrap
gem 'therubyracer', platforms: :ruby
gem 'less-rails'
gem 'twitter-bootstrap-rails', github: 'seyhunak/twitter-bootstrap-rails', branch: 'bootstrap3'
gem 'simple_form', git: 'https://github.com/plataformatec/simple_form.git'

#User Authentication
gem 'devise'
gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'cancancan'

group :doc do
  gem 'sdoc', require: false
end

group :production do
  gem 'rails_12factor'
  gem 'airbrake'
  gem 'asset_sync'
end

group :development do
  gem 'erb2haml'
  gem 'rack-mini-profiler'
  gem 'rails-erd'
  gem 'transpec'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'annotate'
  gem 'rack-dev-mark'
  gem 'bullet'
end

group :test do
  gem 'rake'
  gem 'faker'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'travis'
  gem 'rspec-rails'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'pry-rails'
end
