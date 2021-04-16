# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/level"
require "dry/logger/backends/io"
require "dry/logger/backends/file"

module Dry
  module Logger
    include Level

    def self.new(stream: $stdout, **opts)
      backend =
        case stream
        when IO, StringIO then Backends::IO
        when String, Pathname then Backends::File
        else
          raise ArgumentError, "unsupported stream type #{stream.class}"
        end

      backend.new(stream: stream, **opts)
    end
  end
end
