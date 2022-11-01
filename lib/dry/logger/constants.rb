# frozen_string_literal: true

require "logger"
require "dry/core/constants"

module Dry
  module Logger
    include Dry::Core::Constants

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
