# frozen_string_literal: true

require "logger"

# we need it for iso8601 method
require "time"

require "dry/logger/filter"

module Dry
  module Logger
    module Formatters
      # Dry::Logger default formatter.
      # This formatter returns string in key=value format.
      # Originaly copied from hanami/utils (see Hanami::Logger)
      #
      # @since 0.1.0
      # @api private
      #
      # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html
      class String < ::Logger::Formatter
        # @since 0.1.0
        # @api private
        SEPARATOR = " "

        # @since 0.1.0
        # @api private
        NEW_LINE = $/

        # @since 0.1.0
        # @api private
        RESERVED_KEYS = %i[app severity time].freeze

        # @since 0.1.0
        # @api private
        HASH_SEPARATOR = ","

        # @since 0.1.0
        # @api private
        attr_reader :filter

        def initialize(filters: [], **)
          super()
          @filter = Filter.new(filters)
        end

        # @since 0.1.0
        # @api private
        #
        # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html#method-i-call
        def call(_severity, _time, _progname, msg)
          _format(_message_hash(msg))
        end

        private

        # @since 0.1.0
        # @api private
        def _message_hash(message)
          case message
          when Hash
            filter.call(message)
          when Exception
            Hash[
              message: message.message,
              backtrace: message.backtrace || [],
              error: message.class
            ]
          else
            Hash[message: message]
          end
        end

        # @since 0.1.0
        # @api private
        def _format(hash)
          _format_message(hash)
        end

        # @since 0.1.0
        # @api private
        def _line_front_matter(*args)
          args.map { |string| "[#{string}]" }.join(SEPARATOR)
        end

        # @since 0.1.0
        # @api private
        def _format_message(hash)
          if hash.key?(:error)
            _format_error(hash)
          elsif hash.key?(:params)
            "#{hash.values.join(SEPARATOR)}#{NEW_LINE}"
          else
            "#{_format_params(hash[:message] || hash)}#{NEW_LINE}"
          end
        end

        def _format_params(params)
          case params
          when ::Hash
            params.map { |key, value| "#{key}=#{value.inspect}" }.join(HASH_SEPARATOR)
          else
            params.to_s
          end
        end

        # @since 0.1.0
        # @api private
        def _format_error(hash)
          result = [hash[:error], hash[:message]].compact.join(": ").concat(NEW_LINE)
          hash[:backtrace].each do |line|
            result << "from #{line}#{NEW_LINE}"
          end

          result
        end
      end
    end
  end
end
