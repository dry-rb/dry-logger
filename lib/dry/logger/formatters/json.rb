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
        # @since 0.1.0
        # @api private
        def call(_severity, _time, _progname, entry)
          ::JSON.generate(entry.as_json)
        end
      end
    end
  end
end
