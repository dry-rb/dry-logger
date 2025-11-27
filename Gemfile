# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

group :test do
  gem "sequel"
  gem "sqlite3", platforms: :ruby
  gem "jdbc-sqlite3", platforms: :jruby
end
