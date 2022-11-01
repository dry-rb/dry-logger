# frozen_string_literal: true

require "logger"
require "pathname"

require "dry/logger/constants"

require "dry/logger/backends/io"
require "dry/logger/backends/file"

module Dry
  def self.Logger(id, **opts, &block)
    Logger::Dispatcher.setup(id, **opts, &block)
  end

  module Logger
    LOG_METHODS = %i[debug error fatal info warn].freeze

    BACKEND_METHODS = %i[close].freeze

    def self.new(stream: $stdout, **opts)
      backend =
        case stream
        when IO, StringIO then Backends::IO
        when String, Pathname then Backends::File
        else
          raise ArgumentError, "unsupported stream type #{stream.class}"
        end

      formatter_opt = opts[:formatter]

      formatter =
        case formatter_opt
        when Symbol then formatters.fetch(formatter_opt).new(**opts)
        when Class then formatter_opt.new(**opts)
        when NilClass then formatters[:string].new(**opts)
        when ::Logger::Formatter then formatter_opt
        else
          raise ArgumentError, "unsupported formatter option #{formatter_opt.inspect}"
        end

      backend_opts = opts.select { |key, _| BACKEND_OPT_KEYS.include?(key) }

      backend.new(stream: stream, **backend_opts, formatter: formatter)
    end

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

      def call(meth, *args)
        backends.each do |backend|
          backend.public_send(meth, *args)
        end
      end

      def log(meth, *args)
        call(meth, *args)
        true
      end

      def add_backend(backend = nil, **opts)
        backends << (backend || Dry::Logger.new(**opts))
        self
      end
    end
  end
end
