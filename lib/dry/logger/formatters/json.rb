# frozen_string_literal: true

require "json"
require "dry/logger/formatters/structured"

module Dry
  module Logger
    module Formatters
      # Dry::Logger JSON formatter.
      # This formatter returns string in JSON format.
      #
      # @since 0.1.0
      # @api private
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
