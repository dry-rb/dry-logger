# frozen_string_literal: true

# this file is synced from dry-rb/template-gem project

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dry/logger/version"

Gem::Specification.new do |spec|
  spec.name          = "dry-logger"
  spec.authors       = ["Luca Guidi"]
  spec.email         = ["me@lucaguidi.com"]
  spec.license       = "MIT"
  spec.version       = Dry::Logger::VERSION.dup

  spec.summary       = "Logging for Ruby"
  spec.description   = spec.summary
  spec.homepage      = "https://dry-rb.org/gems/dry-logger"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "dry-logger.gemspec", "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["changelog_uri"]     = "https://github.com/dry-rb/dry-logger/blob/master/CHANGELOG.md"
  spec.metadata["source_code_uri"]   = "https://github.com/dry-rb/dry-logger"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/dry-rb/dry-logger/issues"

  spec.required_ruby_version = ">= 2.5.0"

  # to update dependencies edit project.yml
  spec.add_runtime_dependency "dry-core", "~> 0.5"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
