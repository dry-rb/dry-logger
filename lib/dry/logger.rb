# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/level"

require "dry/logger/backends/io"
require "dry/logger/backends/file"

require "dry/logger/formatters/string"
require "dry/logger/formatters/json"
require "dry/logger/formatters/application"

module Dry
  module Logger
    include Level

    def self.formatters
      @formatters ||= {}
    end

    def self.register_formatter(name, formatter)
      formatters[name] = formatter
    end

    register_formatter(:string, Formatters::String)
    register_formatter(:json, Formatters::JSON)
    register_formatter(:application, Formatters::Application)

    def self.new(stream: $stdout, **opts)
      backend =
        case stream
        when IO, StringIO then Backends::IO
        when String, Pathname then Backends::File
        else
          raise ArgumentError, "unsupported stream type #{stream.class}"
        end

      formatter_opt = opts[:formatter]

      formatter =
        case formatter_opt
        when Symbol then formatters.fetch(formatter_opt).new(**opts)
        when Class then formatter_opt.new(**opts)
        when NilClass then formatters[:string].new(**opts)
        when ::Logger::Formatter then formatter_opt
        else
          raise ArgumentError, "unsupported formatter option #{formatter_opt.inspect}"
        end

      backend.new(stream: stream, **opts, formatter: formatter)
    end
  end
end
