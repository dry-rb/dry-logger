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
      attr_reader :options

      # Set up a dispatcher
      #
      # @since 1.0.0
      #
      # @param [String, Symbol] id The dispatcher id, can be used as progname in log entries
      # @param [Hash] **opts Options that can be used for both the backend and formatter
      #
      # @return [Dispatcher]
      # @api public
      def self.setup(id, **options)
        dispatcher = new(id, **DEFAULT_OPTS, **options)
        dispatcher.add_backend if dispatcher.backends.empty?
        dispatcher
      end

      # @since 1.0.0
      # @api private
      def initialize(id, backends: [], **options)
        @id = id
        @backends = backends
        @options = {**options, progname: id}
      end

      # Log an entry with UNKNOWN severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def unknown(message = nil, **payload)
        log(:unknown, message, **payload)
      end

      # Log an entry with DEBUG severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def debug(message = nil, **payload)
        log(:debug, message, **payload)
      end

      # Log an entry with INFO severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def info(message = nil, **payload)
        log(:info, message, **payload)
      end

      # Log an entry with WARN severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def warn(message = nil, **payload)
        log(:warn, message, **payload)
      end

      # Log an entry with ERROR severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def error(message = nil, **payload)
        log(:error, message, **payload)
      end

      # Log an entry with FATAL severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def fatal(message = nil, **payload)
        log(:fatal, message, **payload)
      end

      BACKEND_METHODS.each do |name|
        define_method(name) do
          call(name)
        end
      end

      # Return severity level
      #
      # @since 1.0.0
      # @return [Integer]
      # @api public
      def level
        LEVELS[options[:level]]
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
        when Hash then log(severity, nil, **message)
        else
          entry = Entry.new(progname: id, severity: severity, message: message, payload: payload)

          each_backend { |backend| backend.__send__(severity, entry) if backend.log?(entry) }
        end

        true
      end

      # Add a new backend to an existing dispatcher
      #
      # @since 1.0.0
      # @return [Dispatcher]
      # @api public
      def add_backend(instance = nil, **backend_options)
        backend = instance || Dry::Logger.new(**options, **backend_options)
        yield(backend) if block_given?
        backends << backend
        self
      end

      # @since 1.0.0
      # @api private
      def each_backend(*_args, &block)
        backends.each(&block)
      end

      # Pass logging to all configured backends
      #
      # @since 1.0.0
      # @return [true]
      # @api private
      def call(meth, ...)
        each_backend { |backend| backend.public_send(meth, ...) }
        true
      end
    end
  end
end
