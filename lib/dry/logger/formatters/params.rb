# frozen_string_literal: true

require "dry/logger/formatters/structured"

module Dry
  module Logger
    module Formatters
      # Special handling of `:params` in the log entry payload
      #
      # @since 1.0.0
      # @api private
      #
      # @see String
      class Params < String
        # @since 1.0.0
        # @api private
        def format_entry(entry)
          if entry.key?(:params)
            entry[:params]
          else
            super
          end
        end
      end
    end
  end
end
