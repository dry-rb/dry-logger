# frozen_string_literal: true

require "logger"
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
      class Structured < ::Logger::Formatter
        # @since 1.0.0
        # @api private
        DEFAULT_FILTERS = [].freeze

        # @since 1.0.0
        # @api private
        NOOP_FILTER = -> message { message }

        # @since 1.0.0
        # @api private
        NEW_LINE = $/ # rubocop:disable Style/SpecialGlobalVars

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
          format(entry.filter(filter))
        end

        # Format entry into a loggable object
        #
        # Custom formatters should override this method
        #
        # @api since 1.0.0
        # @return [Entry]
        # @api public
        def format(entry)
          entry
        end
      end
    end
  end
end
