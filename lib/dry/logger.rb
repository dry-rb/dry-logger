# frozen_string_literal: true

require "dry/logger/constants"
require "dry/logger/dispatcher"

require "dry/logger/formatters/string"
require "dry/logger/formatters/json"
require "dry/logger/formatters/application"

module Dry
  module Logger
    def self.formatters
      @formatters ||= {}
    end

    def self.register_formatter(name, formatter)
      formatters[name] = formatter
    end

    register_formatter(:string, Formatters::String)
    register_formatter(:json, Formatters::JSON)
    register_formatter(:application, Formatters::Application)
  end
end
