# frozen_string_literal: true

require "stringio"

require "dry/logger/constants"
require "dry/logger/dispatcher"

require "dry/logger/formatters/string"
require "dry/logger/formatters/rack"
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
  #   logger.error("Gaaah!")
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

    # Register a new template
    #
    # @example
    #   Dry::Logger.register_template(:request, "[%<severity>s] %<verb>s %<path>s")
    #
    #   logger = Dry.Logger(:my_app, template: :request)
    #
    #   logger.info(verb: "GET", path: "/users")
    #   # [INFO] GET /users
    #
    # @since 1.0.0
    # @return [Hash]
    # @api public
    def self.register_template(name, template)
      templates[name] = template
      templates
    end

    # Build a logging backend instance
    #
    # @since 1.0.0
    # @return [Backends::Stream]
    # @api private
    def self.new(stream: $stdout, **options)
      backend =
        case stream
        when IO, StringIO then Backends::IO
        when String, Pathname then Backends::File
        else
          raise ArgumentError, "unsupported stream type #{stream.class}"
        end

      formatter_spec = options[:formatter]
      template_spec = options[:template]

      template =
        case template_spec
        when Symbol then templates.fetch(template_spec)
        when String then template_spec
        when nil then templates[:default]
        else
          raise ArgumentError,
                ":template option must be a Symbol or a String (`#{template_spec}` given)"
        end

      formatter_options = {**options, template: template}

      formatter =
        case formatter_spec
        when Symbol then formatters.fetch(formatter_spec).new(**formatter_options)
        when Class then formatter_spec.new(**formatter_options)
        when nil then formatters[:string].new(**formatter_options)
        when ::Logger::Formatter then formatter_spec
        else
          raise ArgumentError, "Unsupported formatter option #{formatter_spec.inspect}"
        end

      backend_options = options.select { |key, _| BACKEND_OPT_KEYS.include?(key) }

      backend.new(stream: stream, **backend_options, formatter: formatter)
    end

    # Internal formatters registry
    #
    # @since 1.0.0
    # @api private
    def self.formatters
      @formatters ||= {}
    end

    # Internal templates registry
    #
    # @since 1.0.0
    # @api private
    def self.templates
      @templates ||= {}
    end

    register_formatter(:string, Formatters::String)
    register_formatter(:rack, Formatters::Rack)
    register_formatter(:json, Formatters::JSON)

    register_template(:default, "%<message>s %<payload>s")

    register_template(:rack, <<~STR)
      [%<progname>s] [%<severity>s] [%<time>s] \
      %<verb>s %<status>s %<elapsed>s %<ip>s %<path>s %<length>s %<payload>s
        %<params>s
    STR
  end
end
