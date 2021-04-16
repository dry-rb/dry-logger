# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/level"
require "dry/logger/formatter"

module Dry
  module Logger
    class Stream < ::Logger
      def initialize(stream: $stdout, level: INFO, formatter: nil, filters: [])
        _safe_create_stream_directory(stream)
        super(stream)

        @stream = stream
        @level = Level[level]

        self.formatter = Formatter.fabricate(formatter, filters)
        freeze
      end

      def close
        super if close?
      end

      private

      def close?
        ![STDOUT, $stdout].include?(@stream)
      end

      def _safe_create_stream_directory(stream)
        Pathname.new(stream).dirname.mkpath
      rescue TypeError
        # if stream isn't a file, ignore TypeError
      end
    end
  end
end
