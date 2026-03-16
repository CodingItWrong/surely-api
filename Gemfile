source "https://rubygems.org"

ruby "4.0.1"

gem "rails", "~> 8.1.2"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 7.2"
gem "rack-cors"
gem "bcrypt"
gem "doorkeeper"
gem "dotenv-rails"
gem "nokogiri"
gem "net-smtp"

group :development do
  gem "standard"
end

group :development, :test do
  gem "rspec-rails"
  gem "coderay"
  gem "debug"
end

group :test do
  gem "factory_bot_rails"
  gem "rspec_junit_formatter"
end

group :production do
  gem "rack-attack"
end
