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
      class Exception < String
        # @see String#initialize
        # @since 1.0.0
        # @api private
        def initialize(**options)
          super
          @template = Template[Logger.templates[:exception]]
        end

        # @since 1.0.0
        # @api private
        def format_backtrace(value)
          value.map { |line| "#{TAB}#{line}" }.join(NEW_LINE)
        end

        # @since 1.0.0
        # @api private
        def format_message(value)
          value.inspect
        end
      end
    end
  end
end
