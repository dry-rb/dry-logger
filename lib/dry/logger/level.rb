# frozen_string_literal: true

require "logger"

module Dry
  module Logger
    module Level
      DEBUG = ::Logger::DEBUG
      INFO = ::Logger::INFO
      WARN = ::Logger::WARN
      ERROR = ::Logger::ERROR
      FATAL = ::Logger::FATAL
      UNKNOWN = ::Logger::UNKNOWN

      DEFAULT = INFO

      # @since 0.1.0
      # @api private
      LEVELS = ::Hash[
        "debug" => DEBUG,
        "info" => INFO,
        "warn" => WARN,
        "error" => ERROR,
        "fatal" => FATAL,
        "unknown" => UNKNOWN
      ].freeze

      def self.call(level)
        case level
        when DEBUG..UNKNOWN
          level
        else
          LEVELS.fetch(level.to_s.downcase, DEFAULT)
        end
      end

      class << self
        alias_method :[], :call
      end
    end
  end
end
