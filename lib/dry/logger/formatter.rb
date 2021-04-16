# frozen_string_literal: true

require "set"
require "json"
require "logger"

# we need it for iso8601 method
require "time"

module Dry
  class Logger < ::Logger
    # Dry::Logger default formatter.
    # This formatter returns string in key=value format.
    # Originaly copied from hanami/utils (see Hanami::Logger)
    #
    # @since 0.1.0
    # @api private
    #
    # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html
    class Formatter < ::Logger::Formatter
      require "dry/logger/filter"

      # @since 0.1.0
      # @api private
      SEPARATOR = " "

      # @since 0.1.0
      # @api private
      NEW_LINE = $/

      # @since 0.1.0
      # @api private
      RESERVED_KEYS = %i[app severity time].freeze

      # @since 0.1.0
      # @api private
      HASH_SEPARATOR = ","

      SUBCLASSES = Set.new

      # @since 0.1.0
      # @api private
      def self.fabricate(formatter, filters)
        fabricated_formatter = _formatter_instance(formatter)
        fabricated_formatter.filter = Filter.new(filters)
        fabricated_formatter
      end

      # @api private
      def self.inherited(subclass)
        super
        SUBCLASSES << subclass
      end

      # @api private
      def self.eligible?(name)
        name == :default
      end

      # @since 0.1.0
      # @api private
      def self._formatter_instance(formatter)
        case formatter
        when Symbol
          (SUBCLASSES.find { |s| s.eligible?(formatter) } || self).new
        when nil
          new
        else
          formatter
        end
      end
      private_class_method :_formatter_instance

      # @since 0.1.0
      # @api private
      attr_writer :filter

      # @since 0.1.0
      # @api private
      #
      # @see http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger/Formatter.html#method-i-call
      def call(_severity, _time, _progname, msg)
        _format(_message_hash(msg))
      end

      private

      # @since 0.1.0
      # @api private
      def _message_hash(message)
        case message
        when Hash
          @filter.call(message)
        when Exception
          Hash[
            message: message.message,
            backtrace: message.backtrace || [],
            error: message.class
          ]
        else
          Hash[message: message]
        end
      end

      # @since 0.1.0
      # @api private
      def _format(hash)
        _format_message(hash)
      end

      # @since 0.1.0
      # @api private
      def _line_front_matter(*args)
        args.map { |string| "[#{string}]" }.join(SEPARATOR)
      end

      # @since 0.1.0
      # @api private
      def _format_message(hash)
        if hash.key?(:error)
          _format_error(hash)
        elsif hash.key?(:params)
          "#{hash.values.join(SEPARATOR)}#{NEW_LINE}"
        else
          "#{_format_params(hash[:message] || hash)}#{NEW_LINE}"
        end
      end

      def _format_params(params)
        case params
        when ::Hash
          params.map { |key, value| "#{key}=#{value.inspect}" }.join(HASH_SEPARATOR)
        else
          params.to_s
        end
      end

      # @since 0.1.0
      # @api private
      def _format_error(hash)
        result = [hash[:error], hash[:message]].compact.join(": ").concat(NEW_LINE)
        hash[:backtrace].each do |line|
          result << "from #{line}#{NEW_LINE}"
        end

        result
      end
    end

    # Dry::Logger Application formatter.
    # This formatter returns string with application specific format. We need it for hanami propouse
    #
    # @since 0.1.0
    # @api private
    class ApplicationFormatter < Formatter
      # @api private
      def self.eligible?(name)
        name == :application
      end

      def call(severity, time, _progname, msg)
        _format(severity: severity, time: time, **_message_hash(msg))
      end

      private

      def _format(hash)
        "#{_line_front_matter(hash.delete(:severity),
                              hash.delete(:time))}#{SEPARATOR}#{_format_message(hash)}"
      end

      # @since 0.1.0
      # @api private
      def _line_front_matter(*args)
        args.map { |string| "[#{string}]" }.join(SEPARATOR)
      end
    end

    # Dry::Logger JSON formatter.
    # This formatter returns string in JSON format.
    #
    # @since 0.1.0
    # @api private
    class JSONFormatter < Formatter
      # @api private
      def self.eligible?(name)
        name == :json
      end

      def call(severity, time, _progname, msg)
        _format(severity: severity, time: time, **_message_hash(msg))
      end

      private

      # @since 0.1.0
      # @api private
      def _format(hash)
        hash[:time] = hash[:time].utc.iso8601
        JSON.generate(hash) + NEW_LINE
      end
    end
  end
end
