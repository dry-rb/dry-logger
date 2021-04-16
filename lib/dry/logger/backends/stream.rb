# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/level"

module Dry
  module Logger
    module Backends
      class Stream < ::Logger
        # @since 0.1.0
        # @api private
        attr_reader :stream

        # @since 0.1.0
        # @api private
        attr_reader :level

        # @since 0.1.0
        # @api private
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
