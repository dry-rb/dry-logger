# frozen_string_literal: true

require "set"

require_relative "template"
require_relative "structured"

module Dry
  module Logger
    module Formatters
      # Basic string formatter.
      #
      # This formatter returns log entries in key=value format.
      #
      # @since 1.0.0
      # @api public
      class String < Structured
        # @since 1.0.0
        # @api private
        SEPARATOR = " "

        # @since 1.0.0
        # @api private
        TAB = SEPARATOR * 2

        # @since 1.0.0
        # @api private
        HASH_SEPARATOR = ","

        # @since 1.0.0
        # @api private
        EXCEPTION_SEPARATOR = ": "

        # @since 1.0.0
        # @api private
        attr_reader :template

        # @since 1.0.0
        # @api private
        def initialize(template: Logger.templates[:default], **options)
          super(**options)
          @template = Template[template]
        end

        private

        # @since 1.0.0
        # @api private
        def format(entry)
          output =
            if entry.exception?
              head = template % template_data(entry, exclude: %i[exception])
              tail = format_exception(entry.exception)

              "#{head}#{NEW_LINE}#{TAB}#{tail}"
            else
              template % template_data(entry)
            end

          "#{output}#{NEW_LINE}"
        end

        # @since 1.0.0
        # @api private
        def format_exception(value)
          [
            "#{value.message} (#{value.class})",
            format_backtrace(value.backtrace || EMPTY_BACKTRACE)
          ].join(NEW_LINE)
        end

        # @since 1.0.0
        # @api private
        def format_payload(payload)
          payload.map { |key, value| "#{key}=#{value.inspect}" }.join(SEPARATOR)
        end

        # @since 1.0.0
        # @api private
        def format_backtrace(value)
          value.map { |line| "#{TAB}#{line}" }.join(NEW_LINE)
        end

        # @since 1.0.0
        # @api private
        def format_values(entry)
          entry
            .to_h
            .map { |key, value|
              [key, respond_to?(meth = "format_#{key}", true) ? __send__(meth, value) : value]
            }
            .to_h
        end

        # @since 1.0.0
        # @api private
        def template_data(entry, exclude: EMPTY_ARRAY)
          data = format_values(entry)
          payload = data.except(:message, *entry.meta.keys, *template.tokens, *exclude)
          data[:payload] = format_payload(payload)

          if data[:message]
            data.except(*payload.keys)
          elsif template.include?(:message)
            data[:message] = data.delete(:payload)
            data[:payload] = nil
            data
          else
            data
          end
        end
      end
    end
  end
end
