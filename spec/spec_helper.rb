# frozen_string_literal: true

require_relative "support/coverage"

require "pathname"
require "fileutils"
require "securerandom"

begin
  require "byebug"
rescue LoadError
end

SPEC_ROOT = Pathname(__FILE__).dirname

RELATIVE_TMP = File.join(".", "tmp")
FileUtils.mkdir_p(RELATIVE_TMP)

TMP = SPEC_ROOT.join("..", RELATIVE_TMP).realpath

require_relative "support/rspec_options"

require "dry/logger"

Dir.glob(Pathname.new(__dir__).join("support", "**", "*.rb")).sort.each do |file|
  require_relative file
end

Dir.glob(Pathname.new(__dir__).join("shared", "**", "*.rb")).sort.each do |file|
  require_relative file
end

RSpec.configure do |config|
  global_registries = %i[formatters templates]

  config.around do |example|
    reg_state = global_registries.to_h { |reg| [reg, Dry::Logger.__send__(reg)] }
    example.run
  ensure
    reg_state.each do |reg, val|
      Dry::Logger.instance_variable_set("@#{reg}", val)
    end
  end
end
