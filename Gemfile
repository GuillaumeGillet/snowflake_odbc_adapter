# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in snowflake_odbc_adapter.gemspec
gemspec

gem "rake", "~> 13.0"

gem "minitest", "~> 5.0"

gem "rubocop", "~> 1.21"
gem "rubocop-rails"
gem "rubocop-performance"
gem "rubocop-minitest"

gem "ruby-odbc", git: "https://github.com/vhermecz/ruby-odbc.git", branch: "main"

group :test do
  gem "debug"
  gem "simplecov"
end
