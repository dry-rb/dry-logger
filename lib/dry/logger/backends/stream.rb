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
        # @api public
        attr_accessor :log_if

        # @since 0.1.0
        # @api private
        def initialize(stream:, formatter:, level: DEFAULT_LEVEL, progname: nil, log_if: nil)
          super(stream, progname: progname)

          @stream = stream
          @level = LEVELS[level]

          self.log_if = log_if
          self.formatter = formatter
        end

        # @since 1.0.0
        # @api private
        def log?(entry)
          if log_if
            log_if.call(entry)
          else
            true
          end
        end
      end
    end
  end
end
