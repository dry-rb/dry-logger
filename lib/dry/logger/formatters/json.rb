# frozen_string_literal: true

require "json"
require "dry/logger/formatters/structured"

module Dry
  module Logger
    module Formatters
      # JSON formatter.
      #
      # This formatter returns log entries in JSON format.
      #
      # @since 0.1.0
      # @api public
      class JSON < Structured
        # @since 0.1.0
        # @api private
        def format(entry)
          "#{::JSON.generate(entry.as_json)}#{NEW_LINE}"
        end
      end
    end
  end
end
