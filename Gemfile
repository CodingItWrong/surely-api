source "https://rubygems.org"

ruby "3.2.0"

gem "rails", "~> 7.0.4"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 6.2"
gem "rack-cors"
gem "jsonapi-resources"
gem "jsonapi-resources-optional_paginators", github: "codingitwrong/jsonapi-resources-optional_paginators", ref: "cdaa1e5293235cfe47d4bd8676141c74bd1e663b"
gem "bcrypt"
gem "doorkeeper"
gem "dotenv-rails"
gem "nokogiri"
gem "net-smtp"

group :development do
  gem "listen", ">= 3.0.5", "< 3.9"
  gem "standard"
end

group :development, :test do
  gem "pry-rails"
  gem "rspec-rails"
  gem "coderay"
end

group :test do
  gem "factory_bot_rails"
  gem "rspec_junit_formatter"
end

group :production do
  gem "rack-attack"
end
