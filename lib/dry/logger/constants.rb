# frozen_string_literal: true

require "logger"

module Dry
  module Logger
    # @since 1.0.0
    # @api private
    NEW_LINE = $/ # rubocop:disable Style/SpecialGlobalVars

    # @since 1.0.0
    # @api private
    SEPARATOR = " "

    # @since 1.0.0
    # @api private
    TAB = SEPARATOR * 2

    # @since 1.0.0
    # @api private
    EMPTY_ARRAY = [].freeze

    # @since 1.0.0
    # @api private
    EMPTY_HASH = {}.freeze

    LOG_METHODS = %i[debug info warn error fatal unknown].freeze

    BACKEND_METHODS = %i[close].freeze

    DEBUG = ::Logger::DEBUG
    INFO = ::Logger::INFO
    WARN = ::Logger::WARN
    ERROR = ::Logger::ERROR
    FATAL = ::Logger::FATAL
    UNKNOWN = ::Logger::UNKNOWN

    LEVEL_RANGE = (DEBUG..UNKNOWN).freeze

    DEFAULT_LEVEL = INFO

    # @since 0.1.0
    # @api private
    LEVELS = Hash
      .new { |levels, key|
        LEVEL_RANGE.include?(key) ? key : levels.fetch(key.to_s.downcase, DEFAULT_LEVEL)
      }
      .update(
        "debug" => DEBUG,
        "info" => INFO,
        "warn" => WARN,
        "error" => ERROR,
        "fatal" => FATAL,
        "unknown" => UNKNOWN
      )
      .freeze

    DEFAULT_OPTS = {level: DEFAULT_LEVEL, formatter: nil, progname: nil}.freeze

    BACKEND_OPT_KEYS = DEFAULT_OPTS.keys.freeze
    FORMATTER_OPT_KEYS = %i[filter].freeze
  end
end
