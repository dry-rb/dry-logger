# frozen_string_literal: true

require "dry/logger/formatters/string"

module Dry
  module Logger
    module Formatters
      # Dry::Logger Application formatter.
      # This formatter returns string with application specific format. We need it for hanami propouse
      #
      # @since 0.1.0
      # @api private
      class Application < String
        def call(severity, time, progname, msg)
          _format(progname: progname, severity: severity, time: time, **_message_hash(msg))
        end

        private

        def _format(hash)
          "#{_line_front_matter(
            hash.delete(:progname), hash.delete(:severity), hash.delete(:time)
          )}#{SEPARATOR}#{_format_message(hash)}"
        end

        # @since 0.1.0
        # @api private
        def _line_front_matter(*args)
          args.map { |string| "[#{string}]" }.join(SEPARATOR)
        end
      end
    end
  end
end
