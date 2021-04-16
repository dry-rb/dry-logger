# frozen_string_literal: true

require "json"

require "dry/logger/formatters/string"

module Dry
  module Logger
    module Formatters
      # Dry::Logger JSON formatter.
      # This formatter returns string in JSON format.
      #
      # @since 0.1.0
      # @api private
      class JSON < Formatters::String
        def call(severity, time, _progname, msg)
          _format(severity: severity, time: time, **_message_hash(msg))
        end

        private

        # @since 0.1.0
        # @api private
        def _format(hash)
          hash[:time] = hash[:time].utc.iso8601
          ::JSON.generate(hash) + NEW_LINE
        end
      end
    end
  end
end
