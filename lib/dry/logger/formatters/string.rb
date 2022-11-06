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
        HASH_SEPARATOR = ","

        # @since 1.0.0
        # @api private
        EXCEPTION_SEPARATOR = ": "

        # @since 1.0.0
        # @api private
        DEFAULT_TEMPLATE = "%<message>s"

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
        attr_reader :template

        # @since 1.0.0
        # @api private
        def initialize(filters: DEFAULT_FILTERS, template: DEFAULT_TEMPLATE, **)
          super()
          @filter = filters.equal?(DEFAULT_FILTERS) ? NOOP_FILTER : Filter.new(filters)
          @template = template
        end

        # @since 1.0.0
        # @api private
        #
        # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html#method-i-call
        def call(_severity, _time, _progname, entry)
          format(entry.filter(filter))
        end

        private

        # @since 1.0.0
        # @api private
        def format(entry)
          "#{template % entry.meta.merge(message: format_entry(entry))}#{NEW_LINE}"
        end

        # @since 1.0.0
        # @api private
        def format_entry(entry)
          if entry.exception?
            format_exception(entry)
          # TODO: this should not be here. params is a very web-centric concept and should have its
          #       own formatter
          elsif entry.params?
            entry[:params]
          # TODO: there's no scenario for messages AND payload in specs yet
          elsif entry.message
            entry.message
          else
            format_payload(entry)
          end
        end

        # @since 1.0.0
        # @api private
        def format_exception(entry)
          hash = entry.payload
          message = hash.values_at(:error, :message).compact.join(EXCEPTION_SEPARATOR)
          "#{message}#{NEW_LINE}#{hash[:backtrace].map { |line| "from #{line}" }.join(NEW_LINE)}"
        end

        # @since 1.0.0
        # @api private
        def format_payload(entry)
          entry.map { |key, value| "#{key}=#{value.inspect}" }.join(HASH_SEPARATOR)
        end
      end
    end
  end
end
