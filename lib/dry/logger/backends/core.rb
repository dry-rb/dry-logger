# frozen_string_literal: true

require "dry/logger/constants"

module Dry
  module Logger
    module Backends
      module Core
        # @since 0.1.0
        # @api public
        attr_accessor :log_if

        # @since 1.0.0
        # @api private
        def log?(entry)
          if log_if
            log_if.call(entry)
          else
            true
          end
        end
      end
    end
  end
end
