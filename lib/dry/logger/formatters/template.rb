# frozen_string_literal: true

require "set"

module Dry
  module Logger
    module Formatters
      # Basic string formatter.
      #
      # This formatter returns log entries in key=value format.
      #
      # @since 1.0.0
      # @api public
      class Template
        # @since 1.0.0
        # @api private
        TOKEN_REGEXP = %r[%<(\w*)>s].freeze

        # @since 1.0.0
        # @api private
        MESSAGE_TOKEN = "%<message>s"

        # @since 1.0.0
        # @api private
        attr_reader :value

        # @since 1.0.0
        # @api private
        attr_reader :tokens

        # @since 1.0.0
        # @api private
        def self.[](value)
          cache.fetch(value) { cache[value] = Template.new(value) }
        end

        # @since 1.0.0
        # @api private
        private_class_method def self.cache
          @cache ||= {}
        end

        # @since 1.0.0
        # @api private
        def initialize(value)
          @value = value
          @tokens = value.scan(TOKEN_REGEXP).flatten(1).map(&:to_sym).to_set
        end

        # @since 1.0.0
        # @api private
        def %(tokens)
          value % tokens
        end

        # @since 1.0.0
        # @api private
        def include?(token)
          tokens.include?(token)
        end
      end
    end
  end
end
