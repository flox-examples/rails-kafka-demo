source "https://rubygems.org"
ruby "~> 3.3"

gem "rails", "~> 7.2"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

# Native C extension — requires librdkafka (provided by Devbox)
# USE_SYSTEM_LIBRDKAFKA=true links against Devbox-managed librdkafka
gem "rdkafka", "~> 0.16"

group :development do
  gem "rubocop-rails-omakase", require: false
end

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "webmock", "~> 3.23"
end
