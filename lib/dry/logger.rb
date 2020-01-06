# frozen_string_literal: true

require 'logger'
require 'pathname'

module Dry
  class Logger < ::Logger
    require 'dry/logger/version'
    require 'dry/logger/level'

    def initialize(stream: $stdout, level: INFO)
      _safe_create_stream_directory(stream)
      super(stream)

      @stream = stream
      @level = Level[level]
      freeze
    end

    def close
      super if close?
    end

    private

    def close?
      ![STDOUT, $stdout].include?(@stream)
    end

    def _safe_create_stream_directory(stream)
      Pathname.new(stream).dirname.mkpath
    rescue TypeError # rubocop:disable Lint/HandleExceptions
      # if stream isn't a file, ignore TypeError
    end
  end
end
