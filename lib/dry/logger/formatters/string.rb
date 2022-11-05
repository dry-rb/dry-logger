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
      # @since 1.0.0
      # @api private
      #
      # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html
      class String < ::Logger::Formatter
        # @since 1.0.0
        # @api private
        SEPARATOR = " "

        # @since 1.0.0
        # @api private
        NEW_LINE = $/

        # @since 1.0.0
        # @api private
        RESERVED_KEYS = %i[progname severity time].freeze

        # @since 1.0.0
        # @api private
        HASH_SEPARATOR = ","

        # @since 1.0.0
        # @api private
        DEFAULT_TEMPLATE = "%<message>s"

        # @since 1.0.0
        # @api private
        attr_reader :filter

        # @since 1.0.0
        # @api private
        attr_reader :template

        def initialize(filters: [], template: DEFAULT_TEMPLATE, **)
          super()
          @filter = Filter.new(filters)
          @template = template
        end

        # @since 1.0.0
        # @api private
        #
        # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html#method-i-call
        def call(severity, time, progname, message)
          _format(_message_hash(message, severity: severity, time: time, progname: progname))
        end

        private

        # @since 1.0.0
        # @api private
        def _message_hash(message, options)
          result =
            case message
            when Hash
              filter.call(message).update(options)
            when Exception
              Hash[
                message: message.message,
                backtrace: message.backtrace || [],
                error: message.class,
                **options
              ]
            else
              Hash[message: message, **options]
            end
        end

        # @since 1.0.0
        # @api private
        def _format(hash)
          _format_message(hash)
        end

        # @since 1.0.0
        # @api private
        def _format_message(hash)
          entry =
            if hash.key?(:error)
              template % hash.slice(*RESERVED_KEYS).update(message: _format_error(hash))
            elsif hash.key?(:params)
              template % hash.slice(*RESERVED_KEYS).update(message: hash.except(*RESERVED_KEYS).values.join(SEPARATOR))
            elsif hash.key?(:message)
              template % hash
            else
              template % hash.slice(*RESERVED_KEYS).update(message: _format_params(hash.except(*RESERVED_KEYS)))
            end

          "#{entry}#{NEW_LINE}"
        end

        # @api private
        def _format_params(params)
          case params
          when ::Hash
            params.map { |key, value| "#{key}=#{value.inspect}" }.join(HASH_SEPARATOR)
          else
            params.to_s
          end
        end

        # @since 1.0.0
        # @api private
        def _format_error(hash)
          result = hash.values_at(:error, :message).compact.join(": ")
          "#{result}#{NEW_LINE}#{hash[:backtrace].map { |line| "from #{line}" }.join(NEW_LINE)}"
        end
      end
    end
  end
end
