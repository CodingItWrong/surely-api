source 'https://rubygems.org'

ruby '3.0.0'

gem 'rails', '~> 6.0.3'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 5.1'
gem 'rack-cors'
gem 'jsonapi-resources'
gem 'jsonapi-resources-optional_paginators', github: 'codingitwrong/jsonapi-resources-optional_paginators', ref: 'cdaa1e5293235cfe47d4bd8676141c74bd1e663b'
gem 'bcrypt'
gem 'doorkeeper'
gem 'dotenv-rails'

group :development do
  gem 'listen', '>= 3.0.5', '< 3.4'
  gem 'bullet'
end

group :development, :test do
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'coderay'
  gem 'rubocop'
end

group :test do
  gem 'factory_bot_rails'
  gem 'rspec_junit_formatter'
end

group :production do
  gem 'rack-attack'
end
