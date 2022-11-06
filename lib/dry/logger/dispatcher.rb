# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/constants"
require "dry/logger/entry"

module Dry
  module Logger
    # Logger dispatcher routes log entries to configured logging backends
    #
    # @since 1.0.0
    # @api public
    class Dispatcher
      # @since 1.0.0
      # @api private
      attr_reader :id

      # @since 1.0.0
      # @api private
      attr_reader :backends

      # @since 1.0.0
      # @api private
      attr_reader :opts

      # Set up a dispatcher
      #
      # @since 1.0.0
      #
      # @param [String, Symbol] id The dispatcher id, can be used as progname in log entries
      # @param [Hash] **opts Options that can be used for both the backend and formatter
      #
      # @return [Dispatcher]
      # @api public
      def self.setup(id, **opts)
        if opts.empty?
          new(id, backends: [Dry::Logger.new(**DEFAULT_OPTS)], **DEFAULT_OPTS)
        else
          new(id, backends: [Dry::Logger.new(progname: id, **opts)], **DEFAULT_OPTS, **opts)
        end
      end

      # @!method debug(message = nil, **payload)
      #   Log an entry with DEBUG severity
      #   @see Dispatcher#log
      #   @api public
      #   @return [true]
      # @!method info(message = nil, **payload)
      #   Log an entry with INFO severity
      #   @see Dispatcher#log
      #   @api public
      #   @return [true]
      #   @api public
      # @!method warn(message = nil, **payload)
      #   Log an entry with WARN severity
      #   @see Dispatcher#log
      #   @api public
      #   @return [true]
      #   @api public
      # @!method error(message = nil, **payload)
      #   Log an entry with ERROR severity
      #   @see Dispatcher#log
      #   @api public
      #   @return [true]
      #   @api public
      LOG_METHODS.each do |name|
        define_method(name) do |*args|
          log(name, *args)
        end
      end

      BACKEND_METHODS.each do |name|
        define_method(name) do
          call(name)
        end
      end

      # @since 1.0.0
      # @api private
      def initialize(id, backends:, **opts)
        @id = id
        @backends = backends
        @opts = opts
      end

      # Return severity level
      #
      # @since 1.0.0
      # @return [Integer]
      # @api public
      def level
        LEVELS[opts[:level]]
      end

      # Pass logging to all configured backends
      #
      # @param [Symbol] severity The log severity name
      # @param [String,Symbol,Array] message Optional message object
      # @param [Hash] **payload Optional log entry payload
      #
      # @since 1.0.0
      # @return [true]
      # @api public
      def log(severity, message = nil, **payload)
        case message
        when String, Symbol, Array, Exception
          call(severity, Entry.new(progname: id, severity: severity, message: message, payload: payload))
        when Hash
          call(severity, Entry.new(progname: id, severity: severity, payload: message))
        end

        true
      end

      # Add a new backend to an existing dispatcher
      #
      # @since 1.0.0
      # @return [Dispatcher]
      # @api public
      def add_backend(backend = nil, **opts)
        backends << (backend || Dry::Logger.new(**opts))
        self
      end

      # Pass logging to all configured backends
      #
      # @since 1.0.0
      # @return [true]
      # @api private
      def call(meth, ...)
        backends.each do |backend|
          backend.public_send(meth, ...)
        end
        true
      end
    end
  end
end
