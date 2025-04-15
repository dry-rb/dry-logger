# frozen_string_literal: true

require "logger"

require "dry/logger/constants"
require "dry/logger/backends/core"

module Dry
  module Logger
    module Backends
      class Stream < ::Logger
        include Core

        DEFAULT_SHIFT_AGE = 0
        DEFAULT_SHIFT_SIZE = 1 * 1024 * 1024
        DEFAULT_SHIFT_SUFFIX = "%Y%m%d"

        # @since 0.1.0
        # @api private
        attr_reader :stream

        # @since 0.1.0
        # @api private
        attr_reader :level

        # @since 0.1.0
        # @api private
        def initialize(
          stream:,
          formatter:,
          level: DEFAULT_LEVEL,
          progname: nil,
          log_if: nil,
          shift_age: nil,
          shift_size: nil,
          shift_period_suffix: nil,
          **logger_options
        )
          super(
            stream,
            shift_age || DEFAULT_SHIFT_AGE,
            shift_size || DEFAULT_SHIFT_SIZE,
            shift_period_suffix: shift_period_suffix || DEFAULT_SHIFT_SUFFIX,
            progname: progname,
            **logger_options
          )

          @stream = stream
          @level = LEVELS[level]

          self.log_if = log_if
          self.formatter = formatter
        end

        # @since 1.0.0
        # @api public
        def inspect
          %(#<#{self.class} stream=#{stream} level=#{level} log_if=#{log_if}>)
        end
      end
    end
  end
end