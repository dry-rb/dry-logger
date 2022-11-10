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
          if entry.exception?
            [
              format_payload(entry, Entry::EXCEPTION_PAYLOAD_KEYS),
              format_exception(entry)
            ].reject(&:empty?).join(SEPARATOR)
          else
            format_payload(entry)
          end
        end

        # @since 1.0.0
        # @api private
        def format_payload(entry, excluded_keys = [])
          [*entry.payload.except(:params, *excluded_keys).values, entry[:params]].compact.join(SEPARATOR)
        end
      end
    end
  end
end
