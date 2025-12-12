# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/constants"
require "dry/logger/backends/proxy"
require "dry/logger/entry"
require "dry/logger/execution_context"

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

      # @since 1.0.0
      # @api private
      attr_reader :clock

      # @since 1.0.0
      # @api private
      attr_reader :on_crash

      # @since 1.0.0
      # @api private
      attr_reader :mutex

      # @since 1.0.0
      # @api private
      CRASH_LOGGER = ::Logger.new($stdout).tap { |logger|
        logger.formatter = -> (_, _, _, message) { "#{message}#{NEW_LINE}" }
        logger.level = FATAL
      }.freeze

      # @since 1.0.0
      # @api private
      ON_CRASH = -> (progname:, exception:, message:, payload:) {
        CRASH_LOGGER.fatal(Logger.templates[:crash] % {
          severity: "FATAL",
          progname: progname,
          time: Time.now,
          log_entry: [message, payload].map(&:to_s).reject(&:empty?).join(SEPARATOR),
          exception: exception.class,
          message: exception.message,
          backtrace: TAB + exception.backtrace.join(NEW_LINE + TAB)
        })
      }

      # Set up a dispatcher
      #
      # @since 1.0.0
      # @api private
      #
      # @return [Dispatcher]
      def self.setup(id, **options)
        dispatcher = new(id, **DEFAULT_OPTS, **options)
        yield(dispatcher) if block_given?
        dispatcher.add_backend if dispatcher.backends.empty?
        dispatcher
      end

      # @since 1.0.0
      # @api private
      def initialize(id, backends: [], tags: [], context: {}, **options)
        @id = id
        @backends = backends
        @options = {**options, progname: id}
        @mutex = Mutex.new
        @default_tags = tags.freeze
        @default_context = context.freeze
        @clock = Clock.new(**(options[:clock] || EMPTY_HASH))
        @on_crash = options[:on_crash] || ON_CRASH
      end

      # Log an entry with UNKNOWN severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def unknown(message = nil, **payload, &block)
        log(:unknown, message, **payload, &block)
      end

      # Log an entry with DEBUG severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def debug(message = nil, **payload, &block)
        log(:debug, message, **payload, &block)
      end

      # Log an entry with INFO severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def info(message = nil, **payload, &block)
        log(:info, message, **payload, &block)
      end

      # Log an entry with WARN severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def warn(message = nil, **payload, &block)
        log(:warn, message, **payload, &block)
      end

      # Log an entry with ERROR severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def error(message = nil, **payload, &block)
        log(:error, message, **payload, &block)
      end

      # Log an entry with FATAL severity
      #
      # @see Dispatcher#log
      # @api public
      # @return [true]
      def fatal(message = nil, **payload, &block)
        log(:fatal, message, **payload, &block)
      end

      BACKEND_METHODS.each do |name|
        define_method(name) do
          forward(name)
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
      # @example logging a message
      #   logger.log(:info, "Hello World")
      #
      # @example logging a message by passing a block
      #   logger.log(:debug, "Sidecar") { "Hello World" }
      #
      # @example logging payload
      #   logger.log(:info, verb: "GET", path: "/users")
      #
      # @example logging message and payload
      #   logger.log(:info, "User index request", verb: "GET", path: "/users")
      #
      # @example logging exception
      #   begin
      #     # things that may raise
      #   rescue => e
      #     logger.log(:error, e)
      #     raise e
      #   end
      #
      # @param [Symbol] severity The log severity name
      # @param [String] message Optional message
      # @param [Hash] payload Optional log entry payload
      # @yield
      # @yieldreturn [String] Message to be logged
      #
      # @since 1.0.0
      # @return [true]
      # @api public
      def log(severity, message = nil, **payload, &block) # rubocop:disable Metrics/PerceivedComplexity
        return true if LEVELS[severity] < level

        case message
        when Hash then log(severity, **message, &block)
        else
          if block
            progname = message
            block_result = block.call
            case block_result
            when Hash then payload = block_result
            else
              message = block_result
            end
          end
          progname ||= id

          entry = Entry.new(
            clock: clock,
            progname: progname,
            severity: severity,
            tags: current_tags,
            message: message,
            payload: {**context, **payload}
          )

          each_backend do |backend|
            backend.__send__(severity, entry) if backend.log?(entry)
          rescue StandardError => exception
            on_crash.(progname: id, exception: exception, message: message, payload: payload)
          end
        end

        true
      rescue StandardError => exception
        on_crash.(progname: id, exception: exception, message: message, payload: payload)
        true
      end

      # Shared payload context
      #
      # @example
      #   logger.context[:component] = "test"
      #
      #   logger.info "Hello World"
      #   # Hello World component=test
      #
      # @since 1.0.0
      # @api public
      def context
        @context_key ||= :"context_#{object_id}"
        ExecutionContext[@context_key] ||= @default_context.dup
      end

      # Tagged logging withing the provided block
      #
      # @example
      #   logger.tagged("red") do
      #     logger.info "Hello World"
      #     # Hello World tag=red
      #   end
      #
      #   logger.info "Hello Again"
      #   # Hello Again
      #
      # @since 1.0.0
      # @api public
      def tagged(*tags)
        tags_stack.push(tags)
        yield
      ensure
        tags_stack.pop
      end

      # Add a new backend to an existing dispatcher
      #
      # @example
      #   logger.add_backend(template: "ERROR: %<message>s") { |b|
      #     b.log_if = -> entry { entry.error? }
      #   }
      #
      # @since 1.0.0
      # @return [Dispatcher]
      # @api public
      def add_backend(instance = nil, **backend_options)
        backend =
          case (instance ||= Dry::Logger.new(**options, **backend_options))
          when Backends::Stream then instance
          else Backends::Proxy.new(instance, **options, **backend_options)
          end

        yield(backend) if block_given?

        backends << backend
        self
      end

      # @since 1.0.0
      # @api public
      def inspect
        %(#<#{self.class} id=#{id} options=#{options} backends=#{backends}>)
      end

      # @since 1.0.0
      # @api private
      def each_backend(&block)
        mutex.synchronize do
          backends.each(&block)
        end
      end

      # Pass logging to all configured backends
      #
      # @since 1.0.0
      # @return [true]
      # @api private
      def forward(meth, ...)
        each_backend { |backend| backend.public_send(meth, ...) }
        true
      end

      private

      def tags_stack
        @tags_key ||= :"tags_#{object_id}"
        ExecutionContext[@tags_key] ||= @default_tags.dup
      end

      def current_tags
        tags_stack.flatten
      end
    end
  end
end
