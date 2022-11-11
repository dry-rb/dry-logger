# frozen_string_literal: true

source "https://rubygems.org"

eval_gemfile "Gemfile.devtools"

gemspec

gem "dry-core", github: "dry-rb/dry-core", branch: "main"

gem "pry-byebug", platform: :mri

group :test do
  gem "sequel"
  gem "sqlite3"
end
