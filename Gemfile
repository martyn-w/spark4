source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.3'

gem 'config', '~> 2.2.3'
gem 'faraday', '~> 1.3.1'
gem 'nokogiri', '~>  1.11.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.3'
# Use Puma as the app server
gem 'puma', '~> 5.3.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11.2'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'fakefs', '~> 1.2.2', require: "fakefs/safe"
  gem 'rspec-rails', '~> 4.0'
  gem 'rubocop', '~> 0.88', require: false
  gem 'timecop', '~> 0.9.2'
  gem 'equivalent-xml', '~> 0.6.0'
  gem 'webmock', '~> 3.8.3'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
