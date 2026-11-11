# frozen_string_literal: true

require "logger"

require "dry/logger/constants"
require "dry/logger/filter"

module Dry
  module Logger
    module Formatters
      # Default structured formatter which receives {Logger::Entry} from the backends.
      #
      # This class can be used as the base class for your custom formatters.
      #
      # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html
      #
      # @since 1.0.0
      # @api public
      class Structured < ::Logger::Formatter
        # @since 1.0.0
        # @api private
        DEFAULT_FILTERS = [].freeze

        # @since 1.0.0
        # @api private
        NOOP_FILTER = -> message { message }

        # @since 1.0.0
        # @api private
        attr_reader :filter

        # @since 1.0.0
        # @api private
        attr_reader :options

        # @since 1.0.0
        # @api private
        def initialize(filters: DEFAULT_FILTERS, **options)
          super()
          @filter = filters.equal?(DEFAULT_FILTERS) ? NOOP_FILTER : Filter.new(filters)
          @options = options
        end

        # Filter and then format the log entry into a string
        #
        # Custom formatters typically won't have to override this method because
        # the actual formatting logic is implemented as Structured#format
        #
        # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html#method-i-call
        #
        # @since 1.0.0
        # @return [String]
        # @api public
        def call(_severity, _time, _progname, entry)
          format(entry.filter(filter)) + NEW_LINE
        end

        # Format entry into a loggable object
        #
        # Custom formatters should override this method
        #
        # @api since 1.0.0
        # @return [Entry]
        # @api public
        def format(entry)
          format_values(entry)
        end

        # @since 1.0.0
        # @api private
        def format_values(entry)
          entry.to_h.to_h { |key, value|
            formatter = value_formatter(key)
            [key, formatter ? __send__(formatter, value) : value]
          }
        end

        private

        # @api private
        VALUE_FORMATTERS_LIMIT = 256
        private_constant :VALUE_FORMATTERS_LIMIT

        # Returns the name of the `format_<key>` method for an entry key, or nil if there is none.
        #
        # Names are remembered per key, up to a limit, since payload keys can be arbitrary. The
        # hash is replaced rather than mutated, so formatters shared between threads need no lock.
        #
        # @api private
        def value_formatter(key)
          known = @value_formatters || EMPTY_HASH

          known.fetch(key) {
            name = :"format_#{key}"
            formatter = name if respond_to?(name, true)

            @value_formatters = known.merge(key => formatter).freeze if known.size < VALUE_FORMATTERS_LIMIT

            formatter
          }
        end
      end
    end
  end
end
