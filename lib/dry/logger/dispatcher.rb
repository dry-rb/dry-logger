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
      attr_reader :id

      attr_reader :backends

      attr_reader :opts

      def self.setup(id, **opts)
        if opts.empty?
          new(id, backends: [Dry::Logger.new(**DEFAULT_OPTS)], **DEFAULT_OPTS)
        else
          new(id, backends: [Dry::Logger.new(progname: id, **opts)], **DEFAULT_OPTS, **opts)
        end
      end

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

      def initialize(id, backends:, **opts)
        @id = id
        @backends = backends
        @opts = opts
      end

      def level
        LEVELS[opts[:level]]
      end

      def call(meth, ...)
        backends.each do |backend|
          backend.public_send(meth, ...)
        end
      end

      def log(severity, message = nil, **payload)
        case message
        when String, Symbol, Array, Exception
          call(severity, Entry.new(progname: id, severity: severity, message: message, payload: payload))
        when Hash
          call(severity, Entry.new(progname: id, severity: severity, payload: message))
        end

        true
      end

      def add_backend(backend = nil, **opts)
        backends << (backend || Dry::Logger.new(**opts))
        self
      end
    end
  end
end
