# frozen_string_literal: true

require "dry/logger/formatters/structured"

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
      class String < Structured
        # @since 1.0.0
        # @api private
        SEPARATOR = " "

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
        attr_reader :template

        # @since 1.0.0
        # @api private
        def initialize(template: DEFAULT_TEMPLATE, **options)
          super(**options)
          @template = template
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
