# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "dry-core", github: "dry-rb/dry-core", branch: "main"

if RUBY_VERSION < "3"
  gem "backports"
end

group :test do
  gem "sequel"
  gem "sqlite3"
end
