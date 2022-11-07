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
      class Rack < String
        # @since 1.0.0
        # @api private
        def format_entry(entry)
          [*entry.payload.except(:params).values, entry[:params]].compact.join(SEPARATOR)
        end
      end
    end
  end
end
