# frozen_string_literal: true

module Dry
  module Logger
    # Provides isolated thread-local storage for logger values.
    #
    # @api private
    module ExecutionContext
      CONTEXT_KEY = :__dry_logger__

      class << self
        # Returns a value from the current execution context.
        #
        # @param key [Symbol] the key to retrieve
        #
        # @return [Object, nil] the stored value, or nil if no value has been stored
        def [](key)
          context[key]
        end

        # Sets a value in the current execution context.
        #
        # @param key [Symbol] the key to store
        # @param value [Object] the value to store
        #
        # @return [Object] the stored value
        def []=(key, value)
          context[key] = value
        end

        # Clears all values from the current execution context.
        #
        # @return [self]
        def clear
          current_store[CONTEXT_KEY] = {}
          self
        end

        private

        def context
          current_store[CONTEXT_KEY] ||= {}
        end

        def current_store
          Thread.current
        end
      end
    end
  end
end
