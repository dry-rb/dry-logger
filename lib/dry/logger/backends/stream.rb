# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/level"

module Dry
  module Logger
    module Backends
      class Stream < ::Logger
        attr_reader :stream

        attr_reader :level

        def initialize(stream:, level: INFO, formatter: nil, **)
          super(stream)

          @stream = stream
          @level = Level[level]

          self.formatter = formatter

          freeze
        end
      end
    end
  end
end
