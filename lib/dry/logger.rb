# frozen_string_literal: true

require "dry/logger/global"
require "dry/logger/constants"
require "dry/logger/clock"
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
    extend Global

    # Built-in formatters
    register_formatter(:string, Formatters::String)
    register_formatter(:rack, Formatters::Rack)
    register_formatter(:json, Formatters::JSON)

    # Built-in templates
    register_template(:default, "%<message>s %<payload>s")

    register_template(:details, "[%<progname>s] [%<severity>s] [%<time>s] %<message>s %<payload>s")

    register_template(:rack, <<~STR)
      [%<progname>s] [%<severity>s] [%<time>s] \
      %<verb>s %<status>s %<elapsed>s %<ip>s %<path>s %<length>s %<payload>s
        %<params>s
    STR
  end
end
