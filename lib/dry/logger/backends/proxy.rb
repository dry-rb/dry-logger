# frozen_string_literal: true

require "delegate"
require "dry/logger/constants"

module Dry
  module Logger
    module Backends
      # Logger proxy is used for regular loggers that don't work with log entries
      #
      # @since 1.0.0
      # @api private
      class Proxy < SimpleDelegator
        LOG_METHODS.each do |method|
          define_method(method) { |entry| __getobj__.public_send(method, entry.message) }
        end

        # @since 1.0.0
        # @api private
        def log?(_entry)
          true
        end
      end
    end
  end
end
