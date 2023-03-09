# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

if RUBY_VERSION < "3"
  gem "backports"
end

group :test do
  gem "sequel"
  gem "sqlite3"
end
