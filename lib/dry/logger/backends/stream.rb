# frozen_string_literal: true

require "logger"

require "dry/logger/constants"

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
        def initialize(stream:, level: DEFAULT_LEVEL, formatter:)
          super(stream)

          @stream = stream
          @level = LEVELS[level]

          self.formatter = formatter

          freeze
        end
      end
    end
  end
end
