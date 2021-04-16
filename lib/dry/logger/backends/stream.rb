# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/level"
require "dry/logger/formatter"

module Dry
  module Logger
    module Backends
      class Stream < ::Logger
        attr_reader :stream

        attr_reader :level

        def initialize(stream:, level: INFO, formatter: nil, filters: [])
          super(stream)

          @stream = stream
          @level = Level[level]

          self.formatter = Formatter.fabricate(formatter, filters)

          freeze
        end
      end
    end
  end
end
