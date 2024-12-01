source "https://rubygems.org"

ruby(File.read(".ruby-version").chomp)

gem "rails", "~> 8.0.0"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 6.5"
gem "rack-cors"
gem "jsonapi-resources"
gem "jsonapi-resources-optional_paginators", github: "codingitwrong/jsonapi-resources-optional_paginators", ref: "cdaa1e5293235cfe47d4bd8676141c74bd1e663b"
gem "bcrypt"
gem "doorkeeper"
gem "dotenv-rails"
gem "nokogiri"
gem "net-smtp"
gem "csv"
gem "ostruct"

group :development do
  gem "listen", ">= 3.0.5", "< 3.10"
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
