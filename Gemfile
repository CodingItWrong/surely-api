source "https://rubygems.org"

ruby "4.0.1"

gem "rails", "~> 8.1.3"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 8.0"
gem "rack-cors"
gem "bcrypt"
gem "doorkeeper"
gem "nokogiri"

group :development, :test do
  gem "coderay"
  gem "debug"
  gem "rspec-rails"
  gem "standard"
end

group :test do
  gem "factory_bot_rails"
  gem "rspec_junit_formatter"
end

group :production do
  gem "rack-attack"
end
