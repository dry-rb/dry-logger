# frozen_string_literal: true

require "time"
require "dry/logger/constants"

module Dry
  module Logger
    # @since 1.0.0
    # @api public
    class Entry
      include Enumerable

      # @since 1.0.0
      # @api private
      EMPTY_PAYLOAD = {}.freeze

      # @since 1.0.0
      # @api private
      EMPTY_BACKTRACE = [].freeze

      # @since 1.0.0
      # @api private
      def self.build(progname, severity, ...)
        new(progname: progname, severity: severity, message: message(...), payload: payload(...))
      end

      # @since 1.0.0
      # @api private
      def self.message(*args, **)
        case (value = args[0])
        when String, Array, Symbol, Exception then value
        when Hash then nil
        else
          raise ArgumentError, "+#{value}+ must be either a String or a Hash (#{value.class} given)"
        end
      end

      # @since 1.0.0
      # @api private
      def self.payload(*args, **payload)
        case (value = args[0])
        when String then EMPTY_PAYLOAD
        when Hash then value
        else
          payload
        end
      end

      # @since 1.0.0
      # @api public
      attr_reader :progname

      # @since 1.0.0
      # @api public
      attr_reader :severity

      # @since 1.0.0
      # @api public
      attr_reader :time

      # @since 1.0.0
      # @api public
      attr_reader :message
      alias exception message

      # @since 1.0.0
      # @api public
      attr_reader :payload

      # @since 1.0.0
      # @api private
      def initialize(progname:, severity:, time: Time.now, message:, payload:)
        @progname = progname
        @severity = severity.to_s.upcase # TODO: this doesn't feel right
        @time = time
        @message = message
        @payload = build_payload(payload)
      end

      # @since 1.0.0
      # @api public
      def each(&block)
        payload.each(&block)
      end

      # @since 1.0.0
      # @api public
      def [](name)
        payload[name]
      end

      # @since 1.0.0
      # @api public
      def exception?
        message.is_a?(Exception)
      end

      # @since 1.0.0
      # @api public
      def params?
        payload.key?(:params)
      end

      # @since 1.0.0
      # @api private
      def to_h
        @to_h ||= meta.merge(payload)
      end

      # @since 1.0.0
      # @api private
      def meta
        @meta ||= {progname: progname, severity: severity, time: time}
      end

      # @since 1.0.0
      # @api private
      def utc_time
        @utc_time ||= time.utc.iso8601
      end

      # @since 1.0.0
      # @api private
      def as_json
        # TODO: why are we enforcing UTC in JSON but not in String?
        @as_json ||= to_h.merge(message: message, time: utc_time).compact
      end

      # @since 1.0.0
      # @api private
      def filter(filter)
        @payload = filter.call(payload)
        self
      end

      private

      # @since 1.0.0
      # @api private
      def build_payload(payload)
        if exception?
          {message: exception.message,
           backtrace: exception.backtrace || EMPTY_BACKTRACE,
           error: exception.class,
           **payload}
        else
          payload
        end
      end

    end
  end
end
