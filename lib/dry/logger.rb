# frozen_string_literal: true

require "dry/logger/constants"
require "dry/logger/dispatcher"

require "dry/logger/formatters/string"
require "dry/logger/formatters/json"

require "dry/logger/backends/io"
require "dry/logger/backends/file"

module Dry
  # Set up a logger dispatcher
  #
  # @example Basic $stdout string logger
  #   logger = Dry.Logger(:my_app)
  #
  #   logger.info("Hello World!")
  #   # Hello World!
  #
  # @example Customized $stdout string logger
  #   logger = Dry.Logger(:my_app, template: "[%<severity>][%<time>s] %<message>s")
  #
  #   logger.info("Hello World!")
  #   # [INFO][2022-11-06 10:55:12 +0100] Hello World!
  #
  #   logger.info(Hello: "World!")
  #   # [INFO][2022-11-06 10:55:14 +0100] Hello="World!"
  #
  #   logger.warn("Ooops!")
  #   # [WARN][2022-11-06 10:55:57 +0100] Ooops!
  #
  #   logger.warn("Gaaah!")
  #   # [ERROR][2022-11-06 10:55:57 +0100] Gaaah!
  #
  # @example Basic $stdout JSON logger
  #   logger = Dry.Logger(:my_app, formatter: :json)
  #
  #   logger.info(Hello: "World!")
  #   # {"progname":"my_app","severity":"INFO","time":"2022-11-06T10:11:29Z","Hello":"World!"}
  #
  # @since 1.0.0
  # @return [Dispatcher]
  # @api public
  def self.Logger(id, **opts, &block)
    Logger::Dispatcher.setup(id, **opts, &block)
  end

  module Logger
    # Register a new formatter
    #
    # @example
    #   class MyFormatter < Dry::Logger::Formatters::Structured
    #     def format(entry)
    #       "WOAH: #{entry.message}"
    #     end
    #   end
    #
    #   Dry::Logger.register_formatter(MyFormatter)
    #
    # @since 1.0.0
    # @return [Hash]
    # @api public
    def self.register_formatter(name, formatter)
      formatters[name] = formatter
      formatters
    end

    # Build a logging backend instance
    #
    # @since 1.0.0
    # @return [Backends::Stream]
    # @api private
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

    # Internal formatters registry
    #
    # @since 1.0.0
    # @api private
    def self.formatters
      @formatters ||= {}
    end

    register_formatter(:string, Formatters::String)
    register_formatter(:json, Formatters::JSON)
  end
end
